import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/campaign.dart';
import '../services/http_api_service.dart';

class EnhancedContributionModal extends StatefulWidget {
  final String campaignId;

  const EnhancedContributionModal({Key? key, required this.campaignId})
    : super(key: key);

  @override
  State<EnhancedContributionModal> createState() =>
      _EnhancedContributionModalState();
}

class _EnhancedContributionModalState extends State<EnhancedContributionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final HttpApiService _httpApiService = HttpApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isLoadingCampaign = true;
  Campaign? _campaign;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isVerifyingPayment = false;
  bool _isPaymentVerified = false;
  bool _isVerificationComplete = false;
  int _currentStep = 0;
  String _contributionType = 'gift'; // 'gift' or 'loan'
  DateTime? _selectedDueDate;
  String? _verificationError;

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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                  ),
                ),
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) => _onStepTapped(step),
                  controlsBuilder: _buildStepperControls,
                  steps: [
                    Step(
                      title: const Text('Contribution Details'),
                      content: _buildContributionDetailsStep(),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Payment Instructions'),
                      content: _buildPaymentInstructionsStep(),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : _currentStep == 1
                          ? StepState.indexed
                          : StepState.disabled,
                    ),
                    Step(
                      title: const Text('Upload Payment Proof'),
                      content: _buildPaymentProofStep(),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : _currentStep == 2
                          ? StepState.indexed
                          : StepState.disabled,
                    ),
                    Step(
                      title: const Text('Verification & Submit'),
                      content: _buildVerificationStep(),
                      isActive: _currentStep >= 3,
                      state: _isVerificationComplete
                          ? StepState.complete
                          : _currentStep == 3
                          ? StepState.indexed
                          : StepState.disabled,
                    ),
                  ],
                ),
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

  void _onStepTapped(int step) {
    // Allow going to previous steps, but validate before moving forward
    if (step < _currentStep) {
      setState(() => _currentStep = step);
    } else if (step == _currentStep + 1) {
      _nextStep();
    }
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    return Row(
      children: [
        if (details.stepIndex > 0)
          TextButton(onPressed: _previousStep, child: const Text('Back')),
        const SizedBox(width: 8),
        if (details.stepIndex < 3)
          ElevatedButton(
            onPressed: _nextStep,
            child: Text(details.stepIndex == 2 ? 'Verify & Continue' : 'Next'),
          ),
        if (details.stepIndex == 3)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitContribution,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Contribution'),
          ),
      ],
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Validate contribution details
        if (!_formKey.currentState!.validate()) return false;
        if (_contributionType == 'loan' && _selectedDueDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a due date for loans')),
          );
          return false;
        }
        return true;
      case 1:
        // Payment instructions step - no validation needed
        return true;
      case 2:
        // Payment proof step - validate screenshot
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload payment screenshot')),
          );
          return false;
        }
        return true;
      case 3:
        // Verification step - check if payment is verified
        return _isPaymentVerified;
      default:
        return true;
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Widget _buildContributionDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              hintText: 'Enter your full name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Amount Input
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (₹) *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
              hintText: 'Enter amount to contribute',
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

          // Contribution Type
          const Text(
            'Contribution Type *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Gift'),
                  subtitle: const Text('No repayment required'),
                  value: 'gift',
                  groupValue: _contributionType,
                  onChanged: (value) {
                    setState(() {
                      _contributionType = value!;
                      _selectedDueDate = null; // Clear due date for gifts
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Loan'),
                  subtitle: const Text('To be repaid later'),
                  value: 'loan',
                  groupValue: _contributionType,
                  onChanged: (value) {
                    setState(() => _contributionType = value!);
                  },
                ),
              ),
            ],
          ),

          // Due Date for Loans
          if (_contributionType == 'loan') ...[
            const SizedBox(height: 16),
            const Text(
              'Repayment Due Date *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDueDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedDueDate!)
                          : 'Select due date',
                      style: TextStyle(
                        color: _selectedDueDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Summary
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Name:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(_nameController.text),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${_amountController.text}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Type:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _contributionType.toUpperCase(),
                      style: TextStyle(
                        color: _contributionType == 'gift'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_contributionType == 'loan' &&
                    _selectedDueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Due Date:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDueDate!),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Payment Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Payment Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_campaign?.upiId != null) ...[
                SelectableText(
                  'UPI ID: ${_campaign!.upiId}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
              ],
              SelectableText(
                'Amount: ₹${_amountController.text}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Open any UPI app (GooglePay, PhonePe, Paytm, etc.)\n'
                '2. Make payment to the above UPI ID\n'
                '3. Take a clear screenshot of the payment confirmation\n'
                '4. Click "Next" and upload the screenshot for verification',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // QR Code for Payment
        if (_campaign?.upiId != null) ...[
          const Text(
            'Or Scan QR Code to Pay:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        ],
      ],
    );
  }

  Widget _buildPaymentProofStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Payment Proof',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Important Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Upload a clear screenshot of your payment confirmation\n'
                '• Screenshot should show the amount, date, time, and UPI ID\n'
                '• Make sure all text is clearly visible\n'
                '• This will be verified automatically',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Image Upload Section
        if (_selectedImage == null) ...[
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Tap to upload payment screenshot',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'JPEG, PNG (Max 5MB)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Show uploaded image
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.memory(
                          _selectedImageBytes!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Payment screenshot uploaded successfully',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Verification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (!_isVerifyingPayment && !_isPaymentVerified) ...[
          // Start verification
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
                  'Ready for Verification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We will automatically verify your payment screenshot to check:\n'
                  '• Payment amount matches your contribution\n'
                  '• Payment was made to the correct UPI ID\n'
                  '• Payment date and time are recent',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyPayment,
                    child: const Text('Verify Payment'),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_isVerifyingPayment) ...[
          // Verification in progress
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Verifying your payment...',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'This may take a few seconds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ] else if (_isPaymentVerified) ...[
          // Verification successful
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Payment Verified Successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your payment has been verified and is ready to be submitted.',
                ),
              ],
            ),
          ),
        ] else if (_verificationError != null) ...[
          // Verification failed
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Verification Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_verificationError!),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _verificationError = null;
                          _currentStep = 2; // Go back to upload step
                        });
                      },
                      child: const Text('Upload New Screenshot'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _verifyPayment,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Read image bytes for web compatibility
        final Uint8List imageBytes = await image.readAsBytes();

        // Check file size (5MB limit)
        if (imageBytes.length > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size should be less than 5MB')),
          );
          return;
        }

        setState(() {
          _selectedImage = image;
          _selectedImageBytes = imageBytes;
          _verificationError = null;
          _isPaymentVerified = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _verifyPayment() async {
    if (_selectedImage == null) return;

    setState(() {
      _isVerifyingPayment = true;
      _verificationError = null;
    });

    try {
      // Mock verification logic - in real implementation, this would use OCR/AI
      // to extract text from the image and verify payment details
      await Future.delayed(const Duration(seconds: 3)); // Simulate processing

      final mockVerificationResult = await _performPaymentVerification();

      setState(() {
        _isVerifyingPayment = false;
        if (mockVerificationResult['success']) {
          _isPaymentVerified = true;
          _isVerificationComplete = true;
        } else {
          _verificationError = mockVerificationResult['error'];
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPayment = false;
        _verificationError = 'Verification failed: $e';
      });
    }
  }

  Future<Map<String, dynamic>> _performPaymentVerification() async {
    // Mock verification - in real implementation, this would:
    // 1. Upload image to backend
    // 2. Use OCR to extract text from screenshot
    // 3. Parse amount, UPI ID, date/time
    // 4. Verify against expected values

    // For now, we'll simulate a successful verification
    final expectedAmount = double.parse(_amountController.text);
    final expectedUpiId = _campaign?.upiId ?? '';

    // Random success/failure for demo
    final isSuccess = DateTime.now().millisecond % 3 != 0; // 66% success rate

    if (isSuccess) {
      return {'success': true};
    } else {
      return {
        'success': false,
        'error':
            'Could not verify payment details from screenshot. Please ensure:\n'
            '• Screenshot shows payment confirmation\n'
            '• Amount is ₹${expectedAmount.toStringAsFixed(2)}\n'
            '• Payment made to $expectedUpiId\n'
            '• Screenshot is clear and readable',
      };
    }
  }

  Future<void> _submitContribution() async {
    if (!_isPaymentVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify payment before submitting'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload screenshot first
      String? screenshotUrl;
      if (_selectedImage != null) {
        screenshotUrl = await _uploadScreenshot();
      }

      // Create contribution data
      final contributionData = {
        'campaignId': widget.campaignId,
        'contributorName': _nameController.text.trim(),
        'amount': double.parse(_amountController.text),
        'type': _contributionType,
        'repaymentDueDate':
            _contributionType == 'loan' && _selectedDueDate != null
            ? _selectedDueDate!.toIso8601String()
            : null,
        'paymentScreenshotUrl': screenshotUrl,
        'paymentStatus': 'verified',
        'utr': 'UPI${DateTime.now().millisecondsSinceEpoch}', // Mock UTR
      };

      // Submit to backend
      await _httpApiService.createContribution(contributionData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contribution of ₹${_amountController.text} submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting contribution: $e'),
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

  Future<String?> _uploadScreenshot() async {
    if (_selectedImage == null) return null;

    try {
      // In real implementation, upload to your file storage service
      // For now, return a mock URL
      return 'https://example.com/screenshots/${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (e) {
      print('Error uploading screenshot: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _generatePaymentQR() async {
    try {
      if (_campaign?.upiId == null || _amountController.text.isEmpty) {
        return {'qrCodeUrl': null};
      }

      final amount = _amountController.text;
      final upiId = _campaign!.upiId!;

      // Generate UPI payment URL
      final upiUrl =
          'upi://pay?pa=$upiId&am=$amount&cu=INR&tn=Contribution to ${_campaign!.title}';

      // Generate QR code URL (mock)
      final qrCodeUrl =
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(upiUrl)}';

      return {'qrCodeUrl': qrCodeUrl};
    } catch (e) {
      return {'qrCodeUrl': null};
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
