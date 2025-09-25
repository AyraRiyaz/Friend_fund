import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../models/campaign.dart';
import '../services/http_api_service.dart';
import '../services/payment_verification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/loan_repayment_controller.dart';
import '../theme/app_theme.dart';

class LoanRepaymentScreen extends StatefulWidget {
  final Contribution loanContribution;

  const LoanRepaymentScreen({super.key, required this.loanContribution});

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _utrController = TextEditingController();
  final _remarksController = TextEditingController();
  final HttpApiService _httpApiService = HttpApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isLoadingCampaign = true;
  Campaign? _campaign;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isVerifyingPayment = false;
  bool _isPaymentVerified = false;
  int _currentStep = 0;
  String? _verificationError;
  String? _extractedUtrNumber;
  String _paymentMethod = 'upi';

  // Authentication state
  String? _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _loadCampaignDetails();
  }

  void _checkAuthenticationStatus() {
    final authController = Get.find<AuthController>();
    _loggedInUserName = authController.appwriteUser?.name;
  }

  Future<void> _loadCampaignDetails() async {
    try {
      final campaign = await _httpApiService.getCampaign(
        widget.loanContribution.campaignId,
      );
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
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Repayment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repay Loan'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.primaryViolet),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: _onStepTapped,
          controlsBuilder: _buildStepperControls,
          steps: [
            Step(
              title: const Text('Loan Details'),
              content: _buildLoanDetailsStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Payment Instructions'),
              content: _buildPaymentInstructionsStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Upload Payment Proof'),
              content: _buildPaymentProofStep(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Confirm & Submit'),
              content: _buildConfirmationStep(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loan Information Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryViolet.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryViolet,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loan Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryViolet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Loan Amount:',
                  '₹${widget.loanContribution.amount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Lender:',
                  widget.loanContribution.contributorName,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Campaign:', _campaign?.title ?? 'Loading...'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Loan Date:',
                  _formatDate(widget.loanContribution.date),
                ),
                if (widget.loanContribution.repaymentDueDate != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Due Date:',
                    _formatDate(widget.loanContribution.repaymentDueDate!),
                    isImportant: widget.loanContribution.repaymentDueDate!
                        .isBefore(DateTime.now()),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Method Selection
          Text(
            'Payment Method',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'upi', child: Text('UPI Payment')),
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Text('Bank Transfer'),
              ),
              DropdownMenuItem(value: 'cash', child: Text('Cash Payment')),
            ],
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // UTR Number (for UPI/Bank Transfer)
          if (_paymentMethod != 'cash') ...[
            TextFormField(
              controller: _utrController,
              decoration: InputDecoration(
                labelText: _paymentMethod == 'upi'
                    ? 'UTR Number'
                    : 'Transaction Reference',
                border: const OutlineInputBorder(),
                helperText:
                    'Enter the transaction reference number from your payment',
              ),
              validator: (value) {
                if (_paymentMethod != 'cash' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter the transaction reference number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Optional Remarks
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              border: OutlineInputBorder(),
              helperText: 'Any additional notes about this repayment',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    'Repayment Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Repaying to: ${widget.loanContribution.contributorName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹${widget.loanContribution.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (_paymentMethod == 'upi') ...[
                const Text(
                  '1. Open any UPI app (GooglePay, PhonePe, Paytm, etc.)\n'
                  '2. Make payment to the lender\n'
                  '3. Take a clear screenshot of the payment confirmation\n'
                  '4. Upload the screenshot in the next step for verification',
                  style: TextStyle(fontSize: 14),
                ),
              ] else if (_paymentMethod == 'bank_transfer') ...[
                const Text(
                  '1. Make a bank transfer to the lender\n'
                  '2. Note down the transaction reference number\n'
                  '3. Take a screenshot of the transaction confirmation\n'
                  '4. Upload the screenshot in the next step',
                  style: TextStyle(fontSize: 14),
                ),
              ] else ...[
                const Text(
                  '1. Arrange to meet with the lender\n'
                  '2. Make the cash payment\n'
                  '3. Take a photo of the receipt or ask for a written acknowledgment\n'
                  '4. Upload the photo/receipt in the next step',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contact Information (if available)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryViolet.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.contact_phone, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Lender',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Please coordinate with the lender for payment details (UPI ID, account number, or meeting arrangements).',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: 8),
        const Text(
          'Please upload a clear screenshot or photo of your payment confirmation.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        if (_selectedImage == null) ...[
          // Upload area
          GestureDetector(
            onTap: _selectImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
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
                    'Supports JPG, PNG files',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Display selected image
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  : Image.network(_selectedImage!.path, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isVerifyingPayment ? null : _verifyPayment,
                  icon: _isVerifyingPayment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  label: Text(_isVerifyingPayment ? 'Verifying...' : 'Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_isVerifyingPayment) ...[
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying payment proof...'),
                Text(
                  'This may take a few seconds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],

        if (_isPaymentVerified) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment proof verified successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_verificationError != null) ...[
          const SizedBox(height: 16),
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
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_verificationError!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _verificationError = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Loan Repayment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryViolet.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repayment Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryViolet,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                'Amount:',
                '₹${widget.loanContribution.amount.toStringAsFixed(0)}',
              ),
              _buildSummaryRow('To:', widget.loanContribution.contributorName),
              _buildSummaryRow('Payment Method:', _getPaymentMethodText()),
              if (_utrController.text.isNotEmpty)
                _buildSummaryRow('Reference:', _utrController.text),
              if (_remarksController.text.isNotEmpty)
                _buildSummaryRow('Remarks:', _remarksController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Important Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your repayment will be submitted for verification. The lender will be notified once verified.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isImportant = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isImportant ? Colors.red : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onStepTapped(int step) {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: Text(details.stepIndex == 2 ? 'Verify & Continue' : 'Next'),
          ),
        if (details.stepIndex == 3)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRepayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
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
        return _formKey.currentState!.validate();
      case 1:
        return true; // No validation needed for instructions
      case 2:
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload payment proof')),
          );
          return false;
        }
        if (_isPaymentVerified) return true;
        _verifyPayment();
        return false;
      case 3:
        return _isPaymentVerified;
      default:
        return true;
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _isVerifyingPayment = true;
      _verificationError = null;
    });

    try {
      final verificationResult = await _performPaymentVerification();

      setState(() {
        _isVerifyingPayment = false;
        if (verificationResult['success'] == true) {
          _isPaymentVerified = true;
          _extractedUtrNumber = verificationResult['extractedUtrNumber'];
          if (_extractedUtrNumber != null && _utrController.text.isEmpty) {
            _utrController.text = _extractedUtrNumber!;
          }
          if (mounted) {
            setState(() {
              _currentStep = 3; // Move to final step
            });
          }
        } else {
          _verificationError = verificationResult['error'];
          _currentStep = 2; // Stay on upload step
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPayment = false;
        _verificationError = 'Verification failed. Please try again.';
        _currentStep = 2;
      });
    }
  }

  Future<Map<String, dynamic>> _performPaymentVerification() async {
    if (_selectedImageBytes == null) {
      return {
        'success': false,
        'error': 'No payment proof available for verification',
      };
    }

    try {
      final verificationService = PaymentVerificationService();

      final result = await verificationService.verifyPaymentScreenshot(
        imageBytes: _selectedImageBytes!,
        expectedAmount: widget.loanContribution.amount,
        expectedUpiId: '', // Not needed for repayment verification
        contributorName: _loggedInUserName ?? 'Unknown',
        campaignId: widget.loanContribution.campaignId,
      );

      if (result.isValid) {
        return {
          'success': true,
          'extractedUtrNumber': result.extractedUtrNumber,
        };
      } else {
        return {
          'success': false,
          'error': 'Payment verification failed:\n${result.errors.join('\n')}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }

  Future<void> _submitRepayment() async {
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

      // Submit using LoanRepaymentController
      final loanRepaymentController = Get.find<LoanRepaymentController>();
      final repayment = await loanRepaymentController.createLoanRepayment(
        loanContributionId: widget.loanContribution.id,
        amount: widget.loanContribution.amount,
        utr: _utrController.text.isNotEmpty
            ? _utrController.text
            : _extractedUtrNumber ?? '',
        paymentScreenshotUrl: screenshotUrl ?? '',
      );

      if (mounted && repayment != null) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan repayment of ₹${widget.loanContribution.amount.toStringAsFixed(0)} submitted successfully!',
            ),
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
    if (_selectedImage == null) return null;

    try {
      // In real implementation, upload to file storage service
      return 'https://example.com/repayment-screenshots/${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (e) {
      developer.log(
        'Error uploading screenshot: $e',
        name: 'LoanRepaymentScreen',
      );
      return null;
    }
  }

  String _getPaymentMethodText() {
    switch (_paymentMethod) {
      case 'upi':
        return 'UPI Payment';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash Payment';
      default:
        return _paymentMethod;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  void dispose() {
    _utrController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}
