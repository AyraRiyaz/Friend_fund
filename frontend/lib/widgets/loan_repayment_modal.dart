import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/campaign.dart';
import '../models/user.dart';
import '../services/http_api_service.dart';
import '../services/payment_verification_service.dart';
import '../controllers/loan_repayment_controller.dart';

class LoanRepaymentModal extends StatefulWidget {
  final Contribution loanContribution;

  const LoanRepaymentModal({Key? key, required this.loanContribution})
    : super(key: key);

  @override
  State<LoanRepaymentModal> createState() => _LoanRepaymentModalState();
}

class _LoanRepaymentModalState extends State<LoanRepaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _utrController = TextEditingController();
  final HttpApiService _httpApiService = HttpApiService();
  final ImagePicker _picker = ImagePicker();
  final LoanRepaymentController _loanRepaymentController =
      Get.find<LoanRepaymentController>();

  bool _isSubmitting = false;
  bool _isLoadingContributor = true;
  User? _contributor;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isVerifyingPayment = false;
  bool _isPaymentVerified = false;
  bool _isVerificationComplete = false;
  int _currentStep = 0;
  String? _verificationError;
  String? _extractedUtrNumber;

  // Authentication state - keeping for future use
  // String? _loggedInUserName;
  // String? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _loadContributorDetails();
  }

  void _checkAuthenticationStatus() {
    // Authentication status checking placeholder for future use
    // final authController = Get.find<AuthController>();
    // Store authentication details for future use if needed
    // _loggedInUserId = authController.appwriteUser?.$id;
    // _loggedInUserName = authController.appwriteUser?.name ?? authController.userProfile?.name;
  }

  Future<void> _loadContributorDetails() async {
    try {
      if (widget.loanContribution.contributorId != null) {
        final contributorProfile = await _httpApiService.getUser(
          widget.loanContribution.contributorId!,
        );
        if (mounted) {
          setState(() {
            _contributor = User.fromJson(contributorProfile.toJson());
            _isLoadingContributor = false;
          });
        }
      } else {
        // Anonymous contributor - no UPI ID available
        if (mounted) {
          setState(() {
            _isLoadingContributor = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingContributor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contributor details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContributor) {
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
                      title: const Text('Loan Details'),
                      content: _buildLoanDetailsStep(),
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
              'Repay Loan to ${widget.loanContribution.contributorName}',
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
            onPressed: _isSubmitting ? null : _submitRepayment,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Repayment'),
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
        // Loan details step - always valid as it's just display
        return true;
      case 1:
        // Payment instructions step - always valid
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

  Widget _buildLoanDetailsStep() {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormatter = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Loan Amount:',
                  formatter.format(widget.loanContribution.amount),
                ),
                _buildInfoRow(
                  'Lender:',
                  widget.loanContribution.contributorName,
                ),
                _buildInfoRow(
                  'Loan Date:',
                  dateFormatter.format(widget.loanContribution.date),
                ),
                if (widget.loanContribution.repaymentDueDate != null)
                  _buildInfoRow(
                    'Due Date:',
                    dateFormatter.format(
                      widget.loanContribution.repaymentDueDate!,
                    ),
                  ),
                _buildInfoRow(
                  'Status:',
                  widget.loanContribution.repaymentStatus ?? 'Pending',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_contributor?.upiId != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('UPI ID:', _contributor!.upiId!),
                  _buildInfoRow('Name:', _contributor!.name),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'No UPI ID Available',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The lender (${widget.loanContribution.contributorName}) has not provided a UPI ID. Please contact them directly for repayment instructions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsStep() {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_contributor?.upiId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Contact Required',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact ${widget.loanContribution.contributorName} directly for payment instructions since no UPI ID is available.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  'Amount to pay: ${formatter.format(widget.loanContribution.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('UPI ID: ${_contributor!.upiId}'),
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
        if (_contributor?.upiId != null) ...[
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
          const SizedBox(height: 16),
        ],
        if (_contributor?.upiId != null) ...[
          ElevatedButton.icon(
            onPressed: _copyUpiDetails,
            icon: const Icon(Icons.copy),
            label: const Text('Copy UPI Details'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentProofStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('From Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedImage != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Screenshot Selected',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImageBytes != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                      _isPaymentVerified = false;
                      _verificationError = null;
                    }),
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Image'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  if (!_isPaymentVerified && !_isVerifyingPayment) ...[
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
                            '• Amount matches loan amount\n'
                            '• UTR number extracted\n'
                            '• Payment screenshot is valid',
                          ),
                          if (_extractedUtrNumber != null) ...[
                            const SizedBox(height: 8),
                            Text('UTR: $_extractedUtrNumber'),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_verificationError != null) ...[
                    const SizedBox(height: 16),
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
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _verifyPayment,
                            child: const Text('Retry Verification'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual UTR Entry',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If automatic verification fails, you can manually enter the UTR number:',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _utrController,
                    decoration: const InputDecoration(
                      labelText: 'UTR Number',
                      hintText: 'Enter transaction reference number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isPaymentVerified &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter UTR number or verify payment automatically';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
          _isPaymentVerified = false;
          _verificationError = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _verifyPayment() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment screenshot first'),
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingPayment = true;
      _verificationError = null;
    });

    try {
      final paymentService = PaymentVerificationService();
      final result = await paymentService.verifyPaymentScreenshot(
        imageBytes: _selectedImageBytes!,
        expectedAmount: widget.loanContribution.amount,
        expectedUpiId: _contributor?.upiId ?? '',
        contributorName: widget.loanContribution.contributorName,
      );

      setState(() {
        _isVerifyingPayment = false;
        if (result.isValid) {
          _isPaymentVerified = true;
          _extractedUtrNumber = result.extractedUtrNumber;
          _utrController.text = result.extractedUtrNumber ?? '';
          _isVerificationComplete = true;
        } else {
          _verificationError = result.errors.isNotEmpty
              ? result.errors.first
              : 'Verification failed';
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPayment = false;
        _verificationError = 'Error during verification: $e';
      });
    }
  }

  Future<Map<String, dynamic>> _generatePaymentQR() async {
    try {
      if (_contributor?.upiId == null) {
        return {'qrCodeUrl': null};
      }

      final amount = widget.loanContribution.amount.toString();
      final upiId = _contributor!.upiId!;

      // Generate UPI payment URL
      final upiUrl =
          'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(_contributor!.name)}&am=$amount&cu=INR&tn=${Uri.encodeComponent('Loan Repayment to ${_contributor!.name}')}';

      // Generate QR code URL using qrserver.com API
      final qrCodeUrl =
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(upiUrl)}';

      return {'qrCodeUrl': qrCodeUrl};
    } catch (e) {
      return {'qrCodeUrl': null};
    }
  }

  void _copyUpiDetails() async {
    if (_contributor?.upiId == null) return;

    final details =
        '''
UPI ID: ${_contributor!.upiId}
Name: ${_contributor!.name}
Amount: ₹${widget.loanContribution.amount.toStringAsFixed(2)}
Purpose: Loan Repayment
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

  Future<void> _submitRepayment() async {
    if (!_isPaymentVerified && _utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify payment or enter UTR number'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload screenshot first
      String? screenshotUrl;
      if (_selectedImageBytes != null) {
        screenshotUrl = await _uploadScreenshot();
        if (screenshotUrl == null) {
          throw Exception('Failed to upload screenshot');
        }
      }

      final utrNumber = _extractedUtrNumber ?? _utrController.text.trim();

      // Create loan repayment data matching contribution pattern
      final repaymentData = {
        'loanContributionId': widget.loanContribution.id,
        'amount': widget.loanContribution.amount,
        'utr': utrNumber.isNotEmpty
            ? utrNumber
            : 'UPI${DateTime.now().millisecondsSinceEpoch}',
        'paymentScreenshotUrl': screenshotUrl,
        'paymentStatus': 'verified',
        'repaymentDate': DateTime.now().toIso8601String(),
      };

      // Submit using LoanRepaymentController
      await _loanRepaymentController.createLoanRepayment(
        loanContributionId: widget.loanContribution.id,
        amount: widget.loanContribution.amount,
        utr: repaymentData['utr'] as String,
        paymentScreenshotUrl: screenshotUrl ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan repayment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting repayment: $e'),
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
    if (_selectedImageBytes == null) return null;

    try {
      // Convert to base64
      final base64Image = base64Encode(_selectedImageBytes!);

      // Upload to Appwrite storage via backend
      final uploadResult = await _httpApiService.uploadPaymentScreenshot(
        fileBase64: base64Image,
        fileName: 'loan_repayment_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contributionId: widget.loanContribution.id,
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

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }
}
