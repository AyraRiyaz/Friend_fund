import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/campaign_controller.dart';
import '../theme/app_theme.dart';

class AddCampaignModal extends StatefulWidget {
  const AddCampaignModal({super.key});

  @override
  State<AddCampaignModal> createState() => _AddCampaignModalState();
}

class _AddCampaignModalState extends State<AddCampaignModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _upiIdController = TextEditingController();

  String _selectedPurpose = 'Personal';
  DateTime? _dueDate;
  final CampaignController _campaignController = Get.find<CampaignController>();

  final List<String> _purposes = [
    'Personal',
    'Medical',
    'Education',
    'Emergency',
    'Business',
    'Community',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _campaignController.createCampaign(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      purpose: _selectedPurpose,
      targetAmount: double.parse(_targetAmountController.text.trim()),
      dueDate: _dueDate,
      upiId: _upiIdController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context); // Close modal
      Get.snackbar(
        'Success',
        'Campaign created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: AppTheme.cardDecoration.copyWith(
          boxShadow: AppTheme.cardShadowLarge,
        ),
        child: Column(
          children: [
            // Header
            Container(
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
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Create a New Campaign',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtitle
                      Text(
                        'Share your story and start raising funds for your cause',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Title *',
                          hintText: 'Enter a clear, descriptive title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a campaign title';
                          }
                          if (value.trim().length < 10) {
                            return 'Title must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Purpose Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedPurpose,
                        decoration: const InputDecoration(
                          labelText: 'Purpose *',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: _purposes.map((purpose) {
                          return DropdownMenuItem(
                            value: purpose,
                            child: Text(purpose),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPurpose = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Target Amount Field
                      TextFormField(
                        controller: _targetAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Target Amount (₹) *',
                          hintText: 'Enter target amount in rupees',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter target amount';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          if (amount < 1000) {
                            return 'Minimum target amount is ₹1,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // UPI ID Field
                      TextFormField(
                        controller: _upiIdController,
                        decoration: const InputDecoration(
                          labelText: 'UPI ID *',
                          hintText: 'your-upi-id@bank (e.g., name@paytm)',
                          prefixIcon: Icon(Icons.payment_rounded),
                          helperText:
                              'People will use this UPI ID to contribute',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your UPI ID';
                          }
                          // Basic UPI ID validation - should contain @ symbol
                          if (!value.contains('@')) {
                            return 'Please enter a valid UPI ID (e.g., name@bank)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Due Date Field
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date (Optional)',
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(
                            _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Select due date',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Describe your campaign in detail...',
                          prefixIcon: Icon(Icons.description_rounded),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        maxLength: 1000,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 50) {
                            return 'Description must be at least 50 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Guidelines
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightViolet,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryViolet.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: AppTheme.primaryViolet,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Guidelines',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryViolet,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Be honest and transparent\n'
                              '• Set a realistic target amount\n'
                              '• Provide detailed description\n'
                              '• Keep supporters updated',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Obx(
                    () => ElevatedButton(
                      onPressed: _campaignController.isLoading
                          ? null
                          : _createCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _campaignController.isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Creating...'),
                              ],
                            )
                          : Text(
                              'Create Campaign',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the modal
void showAddCampaignModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddCampaignModal(),
  );
}
