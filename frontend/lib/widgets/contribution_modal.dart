import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../models/campaign.dart';
import '../services/http_api_service.dart';
import '../services/appwrite_service.dart';

class ContributionModal extends StatefulWidget {
  final String campaignId;

  const ContributionModal({Key? key, required this.campaignId})
    : super(key: key);

  @override
  State<ContributionModal> createState() => _ContributionModalState();
}

class _ContributionModalState extends State<ContributionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final HttpApiService _httpApiService = HttpApiService();
  final AppwriteService _appwriteService = AppwriteService();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isLoadingCampaign = true;
  Campaign? _campaign;
  XFile? _selectedImage;
  bool _paymentMade = false;
  bool _isVerifyingPayment = false;
  bool _isPaymentVerified = false;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    try {
      final campaign = await _httpApiService.getCampaign(widget.campaignId);
      if (mounted) {
        setState(() {
          _campaign = campaign;
          _isLoadingCampaign = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCampaign = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading campaign: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCampaign) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _paymentMade
                    ? _buildPaymentVerificationForm()
                    : _buildPaymentDetailsForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Contribute to ${_campaign?.title ?? 'Campaign'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Input
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Payment Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_campaign?.upiId != null) ...[
                  Text('UPI ID: ${_campaign!.upiId}'),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Amount: ₹${_amountController.text.isNotEmpty ? _amountController.text : '_____'}',
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Make payment using any UPI app\n'
                  '2. Take a screenshot of successful payment\n'
                  '3. Click "I Made Payment" and upload screenshot',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Code (Dynamic generation for UPI)
          if (_campaign?.upiId != null &&
              _amountController.text.isNotEmpty) ...[
            const Text(
              'Scan QR Code to Pay:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, dynamic>>(
              future: _generatePaymentQR(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData &&
                    snapshot.data!['qrCodeUrl'] != null) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        snapshot.data!['qrCodeUrl'],
                        width: 200,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.qr_code,
                            size: 200,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  return const Text('Unable to generate QR code');
                }
              },
            ),
            const SizedBox(height: 24),
          ],

          // Payment Made Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _markPaymentMade,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('I Made Payment - Upload Screenshot'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Payment Screenshot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Payment Initiated Successfully!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text('Amount: ₹${_amountController.text}'),
              Text('Contributor: ${_nameController.text}'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Image Selection
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: _selectedImage != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Screenshot Selected',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _selectedImage!.name,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Screenshot'),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Tap to Upload Payment Screenshot',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Screenshot should show successful payment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedImage != null && !_isVerifyingPayment
                ? _submitForVerification
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _selectedImage != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            child: _isVerifyingPayment
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Verifying Payment...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    _selectedImage != null
                        ? 'Verify Payment & Submit Contribution'
                        : 'Please Upload Payment Screenshot First',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Back Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _paymentMade = false),
            child: const Text('Back to Payment Details'),
          ),
        ),
      ],
    );
  }

  void _markPaymentMade() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _paymentMade = true;
    });
  }

  Future<Map<String, dynamic>> _generatePaymentQR() async {
    if (_campaign?.upiId == null || _amountController.text.isEmpty) {
      throw Exception('UPI ID or amount not available');
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      throw Exception('Invalid amount');
    }

    try {
      return await _appwriteService.generatePaymentQR(
        campaignId: widget.campaignId,
        upiId: _campaign!.upiId!,
        amount: amount,
      );
    } catch (e) {
      throw Exception('Failed to generate payment QR: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        Fluttertoast.showToast(
          msg: "Screenshot selected successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to pick image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _submitForVerification() async {
    if (_selectedImage == null) {
      Fluttertoast.showToast(
        msg: "Please select a payment screenshot",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isVerifyingPayment = true;
    });

    try {
      // Step 1: Convert image to base64
      final imageBytes = await _selectedImage!.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // Step 2: Send to OCR for verification
      final expectedAmount = double.parse(_amountController.text.trim());
      final ocrResult = await _httpApiService.processPaymentScreenshot(
        imageBase64: imageBase64,
        expectedAmount: expectedAmount,
        contributorName: _nameController.text.trim(),
        campaignId: widget.campaignId,
      );

      setState(() {
        _isPaymentVerified = ocrResult['data']?['autoVerified'] == true;
      });

      if (_isPaymentVerified) {
        // Step 3: If verified, show success and submit contribution
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Payment verified successfully! Contribution recorded.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Step 4: If not verified, show failure message but don't submit
        final confidence =
            ocrResult['data']?['paymentInfo']?['confidence'] ?? 0;
        final extractedAmount =
            ocrResult['data']?['paymentInfo']?['extractedAmount'] ?? 'N/A';

        if (mounted) {
          _showVerificationFailureDialog(
            confidence,
            extractedAmount,
            expectedAmount,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });

        Fluttertoast.showToast(
          msg: "Verification failed: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
      }
    }
  }

  void _showVerificationFailureDialog(
    double confidence,
    String extractedAmount,
    double expectedAmount,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Payment Verification Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We could not verify your payment from the screenshot. Please check:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('• Expected Amount: ₹${expectedAmount.toStringAsFixed(2)}'),
              Text('• Detected Amount: ₹$extractedAmount'),
              Text(
                '• Confidence Score: ${(confidence * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 16),
              const Text(
                'Common issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Screenshot is blurry or unclear'),
              const Text('• Amount doesn\'t match exactly'),
              const Text('• Transaction was unsuccessful'),
              const Text('• Wrong payment recipient'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ Your contribution has NOT been recorded. Please try again with a clear screenshot of a successful payment.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
