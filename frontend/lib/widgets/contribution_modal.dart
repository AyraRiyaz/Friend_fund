import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/campaign.dart';
import '../services/appwrite_service.dart';
import '../services/razorpay_service.dart';
import '../services/http_api_service.dart';

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

  Campaign? _campaign;
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  // Razorpay
  late RazorpayService _razorpayService;
  late HttpApiService _httpApiService;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _httpApiService = HttpApiService();
    _razorpayService = RazorpayService();
    _razorpayService.onPaymentSuccess = _handlePaymentSuccess;
    _razorpayService.onPaymentError = _handlePaymentError; 
    _razorpayService.onExternalWallet = _handleExternalWallet;
    _loadCampaign();
  }

  Future<void> _loadCampaign() async {
    try {
      final appwriteService = AppwriteService();
      final response = await appwriteService.getCampaignForContribution(widget.campaignId);
      
      if (response['success']) {
        setState(() {
          _campaign = Campaign.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to load campaign');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading campaign: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _makePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create Razorpay order
      final orderResponse = await _httpApiService.createPaymentOrder(
        amount: amount,
        receipt: 'contribution_${widget.campaignId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!orderResponse['success']) {
        throw Exception(orderResponse['error'] ?? 'Failed to create payment order');
      }

      _currentOrderId = orderResponse['data']['id'];

      // Start Razorpay payment
      await _razorpayService.startPayment(
        amount: amount,
        orderId: _currentOrderId!,
        name: _nameController.text.trim(),
        description: 'Contribution to ${_campaign!.title}',
        email: 'contributor@friendfund.com', // You can ask for email in the form
        contact: '9999999999', // You can ask for phone in the form
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment with backend
      final verificationResponse = await _httpApiService.verifyPayment(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );

      if (verificationResponse['success']) {
        // Create contribution record
        final contributionData = {
          'campaignId': widget.campaignId,
          'contributorName': _nameController.text.trim(),
          'amount': double.parse(_amountController.text),
          'type': 'payment_gateway',
          'contributorId': 'anonymous',
        };

        final paymentData = {
          'paymentId': response.paymentId!,
          'orderId': response.orderId!,
          'signature': response.signature!,
          'amount': double.parse(_amountController.text),
          'status': 'verified',
        };

        final contributionResponse = await _httpApiService.createContributionWithPayment(
          contributionData: contributionData,
          paymentData: paymentData,
        );

        if (contributionResponse['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Thank you for your contribution.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Close modal
          }
        } else {
          throw Exception('Failed to save contribution');
        }
      } else {
        throw Exception('Payment verification failed');
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
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading campaign details...'),
                  ],
                ),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make a Contribution',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'to ${_campaign!.title}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Campaign Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Campaign Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Goal: ₹${_campaign!.targetAmount.toStringAsFixed(0)}'),
                  Text('Raised: ₹${_campaign!.collectedAmount.toStringAsFixed(0)}'),
                  Text('Host: ${_campaign!.hostName}'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contribution Form
            Text(
              'Contribution Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Name Field
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

            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Contribution Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount < 1) {
                  return 'Minimum contribution is ₹1';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Payment Section
            Text(
              'Payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Secure Payment via Razorpay',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Your payment is processed securely through Razorpay.'),
                  const Text('Supports UPI, Cards, Net Banking, and Wallets.'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _makePayment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(_isSubmitting ? 'Processing...' : 'Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Text
            Text(
              'By proceeding, you agree to make a contribution to this campaign. '
              'Your payment will be processed securely.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }
}

// Helper function to show the modal
void showContributionModal(BuildContext context, String campaignId) {
  showDialog(
    context: context,
    builder: (context) => ContributionModal(campaignId: campaignId),
  );
}