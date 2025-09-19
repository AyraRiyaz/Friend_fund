import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/campaign.dart';
import '../services/http_api_service.dart';

class ContributionModal extends StatefulWidget {
  final String campaignId;

  const ContributionModal({Key? key, required this.campaignId}) : super(key: key);

  @override
  State<ContributionModal> createState() => _ContributionModalState();
}

class _ContributionModalState extends State<ContributionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final HttpApiService _httpApiService = HttpApiService();
  
  bool _isSubmitting = false;
  bool _isLoadingCampaign = true;
  Campaign? _campaign;
  XFile? _selectedImage;
  bool _paymentMade = false;
  
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading campaign: $e')),
        );
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
                child: _paymentMade ? _buildPaymentVerificationForm() : _buildPaymentDetailsForm(),
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
                Text('Amount: ₹${_amountController.text.isNotEmpty ? _amountController.text : '_____'}'),
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

          // QR Code (if available)
          if (_campaign?.qrCodeUrl != null) ...[
            const Text(
              'Scan QR Code to Pay:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  _campaign!.qrCodeUrl!,
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.qr_code, size: 200, color: Colors.grey);
                  },
                ),
              ),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 4),
              Text('Amount: ₹${_amountController.text}'),
              Text('Contributor: ${_nameController.text}'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Image Selection
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: _selectedImage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 48, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        'Image Selected: ${_selectedImage!.name}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const Text('Tap to change', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to select payment screenshot'),
                      Text('(JPG, PNG supported)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedImage != null && !_isSubmitting) ? _submitPaymentScreenshot : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit for Verification', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),

        // Back Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSubmitting ? null : () => setState(() => _paymentMade = false),
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

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _submitPaymentScreenshot() async {
    if (_selectedImage == null || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Read image as bytes
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Submit to backend for OCR processing
      final response = await _httpApiService.processPaymentScreenshot(
        imageBase64: base64Image,
        expectedAmount: double.parse(_amountController.text),
        contributorName: _nameController.text.trim(),
        campaignId: widget.campaignId,
      );

      if (mounted) {
        if (response['success']) {
          final bool autoVerified = response['data']['autoVerified'] ?? false;
          final double confidence = response['data']['paymentInfo']['ocrConfidence'] ?? 0;
          
          _showSuccessDialog(autoVerified, confidence);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(bool autoVerified, double confidence) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              autoVerified ? Icons.check_circle : Icons.pending,
              color: autoVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(autoVerified ? 'Payment Verified!' : 'Payment Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              autoVerified
                  ? 'Your payment has been automatically verified and processed!'
                  : 'Your payment screenshot has been submitted for review.',
            ),
            const SizedBox(height: 8),
            Text('Confidence Score: ${confidence.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            if (!autoVerified)
              const Text(
                'Our team will review and verify your payment within 24 hours.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close modal
              Get.snackbar(
                'Success',
                autoVerified
                    ? 'Thank you for your contribution!'
                    : 'Payment submitted for verification',
                backgroundColor: autoVerified ? Colors.green : Colors.orange,
                colorText: Colors.white,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}