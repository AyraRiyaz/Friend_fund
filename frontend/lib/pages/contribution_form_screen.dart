import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campaign.dart';
import '../services/appwrite_service.dart';

class ContributionFormScreen extends StatefulWidget {
  final String campaignId;

  const ContributionFormScreen({Key? key, required this.campaignId})
    : super(key: key);

  @override
  State<ContributionFormScreen> createState() => _ContributionFormScreenState();
}

class _ContributionFormScreenState extends State<ContributionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _utrController = TextEditingController();

  Campaign? _campaign;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _contributionType = 'gift';
  XFile? _paymentScreenshot;
  bool _paymentMade = false;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    try {
      final appwriteService = AppwriteService();
      final response = await appwriteService.getCampaignForContribution(
        widget.campaignId,
      );

      if (response['success']) {
        setState(() {
          _campaign = Campaign.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to load campaign');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading campaign: $e')));
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

    if (_campaign?.upiId == null || _campaign!.upiId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID not available for this campaign')),
      );
      return;
    }

    // Generate UPI payment URL
    final upiUrl =
        'upi://pay?pa=${_campaign!.upiId}'
        '&pn=${Uri.encodeComponent(_campaign!.hostName)}'
        '&am=$amount'
        '&cu=INR'
        '&tn=${Uri.encodeComponent('Contribution to ${_campaign!.title}')}';

    try {
      final uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() => _paymentMade = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment initiated. Please upload payment screenshot after completing payment.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Cannot launch UPI payment');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initiating payment: $e')));
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _paymentScreenshot = image);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_paymentMade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make the payment first')),
      );
      return;
    }

    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment screenshot')),
      );
      return;
    }

    if (_utrController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter UTR number')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appwriteService = AppwriteService();

      // Upload payment screenshot
      String? screenshotUrl;
      if (_paymentScreenshot != null) {
        final uploadResponse = await appwriteService.uploadFile(
          _paymentScreenshot!,
        );
        if (uploadResponse['success']) {
          screenshotUrl = uploadResponse['fileUrl'];
        }
      }

      // Create contribution
      final contributionData = {
        'campaignId': widget.campaignId,
        'contributorName': _nameController.text,
        'amount': double.parse(_amountController.text),
        'type': _contributionType,
        'utrNumber': _utrController.text,
        'paymentScreenshotUrl': screenshotUrl,
        'paymentStatus': 'pending', // Will be verified by host/admin
        'contributorId': 'anonymous', // For now, making anonymous contributions
      };

      final response = await appwriteService.createContribution(
        contributionData,
      );

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Contribution submitted successfully! It will be verified soon.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to submit contribution');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting contribution: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_campaign == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Campaign not found or unavailable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute to Campaign'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Details Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _campaign!.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By ${_campaign!.hostName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _campaign!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target: ₹${_campaign!.targetAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Collected: ₹${_campaign!.collectedAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                          CircularProgressIndicator(
                            value: _campaign!.progressPercentage,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contribution Form
              Text(
                'Your Contribution',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

              DropdownButtonFormField<String>(
                value: _contributionType,
                decoration: const InputDecoration(
                  labelText: 'Contribution Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'gift', child: Text('Gift')),
                  DropdownMenuItem(value: 'loan', child: Text('Loan')),
                ],
                onChanged: (value) {
                  setState(() => _contributionType = value!);
                },
              ),

              const SizedBox(height: 24),

              // Payment Section
              Container(
                width: double.infinity,
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
                        Icon(Icons.payment, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Details',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('UPI ID: ${_campaign!.upiId ?? 'Not available'}'),
                    Text('Recipient: ${_campaign!.hostName}'),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _paymentMade ? null : _makePayment,
                        icon: Icon(_paymentMade ? Icons.check : Icons.payment),
                        label: Text(
                          _paymentMade ? 'Payment Initiated' : 'Pay Now',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _paymentMade
                              ? Colors.green
                              : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_paymentMade) ...[
                const SizedBox(height: 24),

                // Payment Proof Section
                Text(
                  'Payment Proof',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _utrController,
                  decoration: const InputDecoration(
                    labelText: 'UTR Number / Transaction ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter UTR number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (_paymentScreenshot != null) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text('Screenshot uploaded successfully'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickPaymentScreenshot,
                          child: const Text('Change Screenshot'),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text('Upload payment screenshot'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _pickPaymentScreenshot,
                          child: const Text('Choose Image'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitContribution,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Submitting...'),
                            ],
                          )
                        : const Text(
                            'Submit Contribution',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _utrController.dispose();
    super.dispose();
  }
}
