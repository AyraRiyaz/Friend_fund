import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/app_bar_with_menu.dart';
import '../controllers/campaign_controller.dart';

class AddCampaignPage extends StatefulWidget {
  const AddCampaignPage({Key? key}) : super(key: key);

  @override
  State<AddCampaignPage> createState() => _AddCampaignPageState();
}

class _AddCampaignPageState extends State<AddCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

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
    );

    if (success) {
      Get.back(); // Go back to previous page
      Get.snackbar(
        'Success',
        'Campaign created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Create Campaign'),
      drawer: const AppDrawer(),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.campaign, size: 48, color: Colors.teal),
                        const SizedBox(height: 12),
                        Text(
                          'Create a New Campaign',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your story and start raising funds for your cause',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Campaign Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          maxLines: 6,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Guidelines Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Campaign Guidelines',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Be honest and transparent about your purpose\n'
                          '• Set a realistic target amount\n'
                          '• Provide detailed description of fund usage\n'
                          '• Upload relevant documents if possible\n'
                          '• Keep supporters updated on progress',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Create Button
                ElevatedButton(
                  onPressed: _campaignController.isLoading
                      ? null
                      : _createCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _campaignController.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Campaign...'),
                          ],
                        )
                      : const Text(
                          'Create Campaign',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
