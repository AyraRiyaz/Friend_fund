import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/campaign.dart';
import '../services/http_api_service.dart';
import '../services/payment_verification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/contribution_controller.dart';

class EnhancedContributionModal extends StatefulWidget {
  final String campaignId;
  final bool isFromQrCode; // True if accessed via QR code

  const EnhancedContributionModal({
    Key? key,
    required this.campaignId,
    this.isFromQrCode = false,
  }) : super(key: key);

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
  String? _extractedUtrNumber; // Store extracted UTR from payment verification

  // Authentication state
  bool _isUserLoggedIn = false;
  String? _loggedInUserId;
  String? _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _loadCampaignDetails();
  }

  void _checkAuthenticationStatus() {
    final authController = Get.find<AuthController>();
    _isUserLoggedIn = authController.isAuthenticated;

    if (_isUserLoggedIn) {
      _loggedInUserId = authController.appwriteUser?.$id;
      _loggedInUserName =
          authController.appwriteUser?.name ?? authController.userProfile?.name;

      // Pre-fill name if user is logged in
      if (_loggedInUserName != null) {
        _nameController.text = _loggedInUserName!;
      }
    }
    // For QR code users, the authentication card will show appropriate messaging
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
        // Payment proof step - validate screenshot and verify payment
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload payment screenshot')),
          );
          return false;
        }

        // If payment is already verified, allow advancement
        if (_isPaymentVerified) {
          return true;
        }

        // If not verified, trigger verification
        _verifyPayment();
        return false; // Don't advance immediately, let verification complete
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
          // Authentication Status Card
          if (widget.isFromQrCode) _buildAuthenticationStatusCard(),

          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your Name *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
              hintText: 'Enter your full name',
              // Disable editing if user is logged in
              enabled: !_isUserLoggedIn,
              helperText: _isUserLoggedIn ? 'Using your account name' : null,
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

          // Show verification error if any
          if (_verificationError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Verification Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your screenshot and try again. Make sure:\n'
                    '• The payment amount matches your contribution\n'
                    '• Payment was made to the correct UPI ID\n'
                    '• The screenshot is clear and readable\n'
                    '• Payment was made recently (within 7 days)',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _verifyPayment,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload, size: 16),
                        label: const Text('Upload New Screenshot'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                  'We will verify your payment screenshot by analyzing:\n'
                  '• Image quality and format validation\n'
                  '• Payment amount verification\n'
                  '• UPI ID confirmation\n'
                  '• Transaction authenticity check',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Tips for better verification:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Use a clear, high-quality screenshot\n'
                        '• Ensure all text is readable\n'
                        '• Include the full payment confirmation screen\n'
                        '• Avoid cropping important details',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
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
                  'Extracting text from screenshot...',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Using OCR to verify payment details',
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
          _extractedUtrNumber =
              null; // Reset extracted UTR when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _verifyPayment() async {
    if (_selectedImage == null || _selectedImageBytes == null) return;

    setState(() {
      _isVerifyingPayment = true;
      _verificationError = null; // Clear previous error
    });

    try {
      // Show progress to user - OCR can take a few seconds
      await Future.delayed(const Duration(milliseconds: 500));

      final verificationResult = await _performPaymentVerification();

      setState(() {
        _isVerifyingPayment = false;
        if (verificationResult['success']) {
          _isPaymentVerified = true;
          _isVerificationComplete = true;

          // Store extracted UTR number for later use
          _extractedUtrNumber = verificationResult['extractedUtrNumber'];

          // Show success message with extracted details
          final extractedAmount = verificationResult['extractedAmount'];
          final confidence = verificationResult['confidence'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extractedAmount != null
                    ? 'Payment verified! Amount: ₹${extractedAmount.toStringAsFixed(2)} (${(confidence * 100).toStringAsFixed(1)}% confidence)'
                    : 'Payment verified successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Automatically advance to the next step after successful verification
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _currentStep = 3; // Move to final submission step
              });
            }
          });
        } else {
          _verificationError = verificationResult['error'];

          // Stay on upload step (step 2) instead of advancing to verification step
          _currentStep = 2;

          // Show user-friendly error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment verification failed. Please check your screenshot and try again.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.white,
                onPressed: _verifyPayment,
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPayment = false;
        _verificationError =
            'Verification failed due to a technical error. Please try again with a clear screenshot.';
        _currentStep = 2; // Stay on upload step
      });

      // Show user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to verify payment. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Try Again',
            textColor: Colors.white,
            onPressed: _verifyPayment,
          ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _performPaymentVerification() async {
    if (_selectedImageBytes == null) {
      return {
        'success': false,
        'error': 'No payment screenshot available for verification',
      };
    }

    try {
      final verificationService = PaymentVerificationService();

      final result = await verificationService.verifyPaymentScreenshot(
        imageBytes: _selectedImageBytes!,
        expectedAmount: double.parse(_amountController.text),
        expectedUpiId: _campaign?.upiId ?? '',
        contributorName: _nameController.text.trim(),
        campaignId:
            widget.campaignId, // Pass campaign ID for UTR duplication check
      );

      if (result.isValid) {
        return {
          'success': true,
          'confidence': result.confidence,
          'extractedAmount': result.extractedAmount,
          'extractedUpiId': result.extractedUpiId,
          'extractedUtrNumber': result.extractedUtrNumber,
          'extractedDate': result.extractedDate,
        };
      } else {
        return {
          'success': false,
          'error': 'Payment verification failed:\n${result.errors.join('\n')}',
          'confidence': result.confidence,
          'extractedAmount': result.extractedAmount,
          'extractedUpiId': result.extractedUpiId,
          'extractedUtrNumber': result.extractedUtrNumber,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification failed due to technical error: $e',
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

      // Create contribution data with proper contributor handling
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
        'utr':
            _extractedUtrNumber ??
            'UPI${DateTime.now().millisecondsSinceEpoch}', // Use extracted UTR or fallback
        // Authentication-based contributor ID handling
        'contributorId': _isUserLoggedIn ? _loggedInUserId : null,
        'isAnonymous': !_isUserLoggedIn,
      };

      // Submit using ContributionController
      final contributionController = Get.find<ContributionController>();
      final contribution = await contributionController.createContribution(
        contributionData,
      );

      if (mounted && contribution != null) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isUserLoggedIn
                  ? 'Contribution of ₹${_amountController.text} submitted successfully!'
                  : 'Anonymous contribution of ₹${_amountController.text} submitted successfully!',
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
      // Read image bytes
      final imageBytes = await _selectedImage!.readAsBytes();

      // Convert to base64
      final base64Image = base64Encode(imageBytes);

      // Upload to Appwrite storage via backend
      final uploadResult = await HttpApiService().uploadPaymentScreenshot(
        fileBase64: base64Image,
        fileName: 'contribution_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contributionId:
            widget.campaignId, // Use campaignId as contributionId for now
      );

      if (uploadResult['success'] == true) {
        return uploadResult['data']?['fileUrl'] ?? uploadResult['fileUrl'];
      } else {
        throw Exception(uploadResult['error'] ?? 'Upload failed');
      }
    } catch (e) {
      print('Error uploading screenshot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading screenshot: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildAuthenticationStatusCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isUserLoggedIn ? Colors.green : Colors.orange,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _isUserLoggedIn
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isUserLoggedIn
                    ? Icons.account_circle
                    : Icons.account_circle_outlined,
                color: _isUserLoggedIn ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isUserLoggedIn
                      ? 'Signed in as ${_loggedInUserName ?? "User"}'
                      : 'Contributing as Guest',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isUserLoggedIn
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isUserLoggedIn
                ? 'Your contribution will be linked to your account for easy tracking.'
                : 'You\'re contributing anonymously. Sign in to track your contributions and access additional features.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (!_isUserLoggedIn) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to login page
                  Navigator.of(context).pop();
                  Get.toNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
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
