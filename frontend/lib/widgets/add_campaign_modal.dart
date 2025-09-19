import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/campaign_controller.dart';

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

    if (success) {
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create a New Campaign',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtitle
                      Text(
                        'Share your story and start raising funds for your cause',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Campaign Title *',
                          hintText: 'Enter a clear, descriptive title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'Purpose *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'Target Amount (₹) *',
                          hintText: 'Enter target amount in rupees',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'UPI ID *',
                          hintText: 'your-upi-id@bank (e.g., name@paytm)',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          decoration: InputDecoration(
                            labelText: 'Due Date (Optional)',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Describe your campaign in detail...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Guidelines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Be honest and transparent\n'
                              '• Set a realistic target amount\n'
                              '• Provide detailed description\n'
                              '• Keep supporters updated',
                              style: TextStyle(fontSize: 12),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: _campaignController.isLoading
                          ? null
                          : _createCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                                SizedBox(width: 8),
                                Text('Creating...'),
                              ],
                            )
                          : const Text('Create Campaign'),
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
