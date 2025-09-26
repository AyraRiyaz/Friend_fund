import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campaign.dart';
import '../services/http_api_service.dart';
import '../services/payment_verification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/contribution_controller.dart';
import '../theme/app_theme.dart';

class EnhancedContributionModal extends StatefulWidget {
  final String campaignId;
  final bool isFromQrCode; // True if accessed via QR code

  const EnhancedContributionModal({
    super.key,
    required this.campaignId,
    this.isFromQrCode = false,
  });

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
      decoration: AppTheme.primaryGradientDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Contribute to ${_campaign?.title ?? 'Campaign'}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
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
        if (details.stepIndex == 3 && _isPaymentVerified)
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
        // Payment proof step - require image
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload payment screenshot')),
          );
          return false;
        }
        return true;
      case 3:
        // Verification step - require verification
        if (!_isPaymentVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify payment details first'),
            ),
          );
          return false;
        }
        return true;
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
          color: AppTheme.lightViolet,
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amount to pay: ₹${_amountController.text}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_campaign?.upiId != null) ...[
                  const SizedBox(height: 8),
                  Text('UPI ID: ${_campaign!.upiId}'),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Steps to complete payment:\n'
                  '1. Open any UPI app (GooglePay, PhonePe, Paytm, etc.)\n'
                  '2. Make payment to the above UPI ID\n'
                  '3. Take a screenshot of the payment confirmation\n'
                  '4. Upload the screenshot in the next step',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Copy UPI Details Button
        if (_campaign?.upiId != null) ...[
          ElevatedButton.icon(
            onPressed: _copyUpiDetails,
            icon: const Icon(Icons.copy),
            label: const Text('Copy UPI Details'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
        ],

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

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Payment Screenshot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please upload a clear screenshot of your payment confirmation that shows:\n'
                  '• Transaction amount\n'
                  '• Date and time\n'
                  '• Screenshot should show the amount, date, time, and UPI ID\n'
                  '• UTR/Transaction reference number',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Single Upload Button
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.screenshot),
          label: const Text('Upload Screenshot'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),

        // Show selected image info
        if (_selectedImage != null) ...[
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Verification Failed',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _verifyPayment,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
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

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Verification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isPaymentVerified && !_isVerifyingPayment && _verificationError == null) ...[
                  const Text(
                    'Click "Verify Payment" to automatically extract and verify payment details from your screenshot.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _verifyPayment,
                    icon: const Icon(Icons.verified),
                    label: const Text('Verify Payment'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else if (_isVerifyingPayment) ...[
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Verifying payment details...'),
                      ],
                    ),
                  ),
                ] else if (_isPaymentVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Verified',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Payment details have been successfully verified:\n'
                          '• Amount matches contribution amount\n'
                          '• UTR number extracted\n'
                          '• Payment screenshot is valid',
                        ),
                        if (_extractedUtrNumber != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Extracted UTR Number:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _extractedUtrNumber!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (_verificationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Verification Failed',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_verificationError!),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _verificationError = null;
                                    _isPaymentVerified = false;
                                    _isVerificationComplete = false;
                                  });
                                  _verifyPayment();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry Verification'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _selectedImageBytes = null;
                                    _isPaymentVerified = false;
                                    _verificationError = null;
                                    _extractedUtrNumber = null;
                                    _isVerificationComplete = false;
                                    _currentStep = 2;
                                  });
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload New'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _copyUpiDetails() async {
    if (_campaign?.upiId == null) return;

    final details = '''
UPI ID: ${_campaign!.upiId}
Campaign: ${_campaign!.title}
Amount: ₹${_amountController.text}
Purpose: Contribution
''';

    try {
      await Clipboard.setData(ClipboardData(text: details));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI details copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy UPI details'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size should be less than 5MB'),
              ),
            );
          }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
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

          // Payment verification success is shown in the modal UI

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

          // Verification error is shown in the modal UI
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPayment = false;
        _verificationError =
            'Verification failed due to a technical error. Please try again with a clear screenshot.';
        _currentStep = 2; // Stay on upload step
      });

      // Verification error is shown in the modal UI
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
          content: Text('Please verify payment first'),
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
        'utr': _extractedUtrNumber?.replaceAll(RegExp(r'\s+'), '') ?? 
            'UPI${DateTime.now().millisecondsSinceEpoch}', // Normalize UTR or fallback
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
      }
    } catch (e) {
      // Error handling is done through the modal UI
      developer.log('Error submitting contribution: $e', name: 'ContributionModal');
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
      developer.log(
        'Error uploading screenshot: $e',
        name: 'ContributionModal',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading screenshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
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
                  foregroundColor: AppTheme.primaryViolet,
                  side: const BorderSide(color: AppTheme.primaryViolet),
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
