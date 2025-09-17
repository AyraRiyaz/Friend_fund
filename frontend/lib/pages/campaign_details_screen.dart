import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../components/app_bar_with_menu.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  bool get isMyOwnCampaign {
    final authController = Get.find<AuthController>();
    return widget.campaign.hostId == authController.appwriteUser?.$id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Campaign Details'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampaignHeader(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            const SizedBox(height: 16),
            if (isMyOwnCampaign) ...[
              _buildHostActions(),
              const SizedBox(height: 16),
              _buildContributionsManagement(),
            ] else ...[
              _buildContributeSection(),
              const SizedBox(height: 16),
              _buildPublicContributions(),
            ],
            const SizedBox(height: 16),
            _buildCampaignInfo(),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: isMyOwnCampaign
          ? _buildHostFAB()
          : _buildContributorFAB(),
    );
  }

  Widget _buildCampaignHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.secondaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.campaign.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.campaign.purpose,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.campaign.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Hosted by ${widget.campaign.hostName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(widget.campaign.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (widget.campaign.status.toLowerCase()) {
      case 'active':
        chipColor = AppTheme.success;
        statusText = 'Active';
        break;
      case 'closed':
        chipColor = Colors.grey;
        statusText = 'Closed';
        break;
      case 'paused':
        chipColor = Colors.orange;
        statusText = 'Paused';
        break;
      default:
        chipColor = AppTheme.primaryBlue;
        statusText = widget.campaign.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercentage = widget.campaign.progressPercentage;
    final remainingAmount =
        widget.campaign.targetAmount - widget.campaign.collectedAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Funding Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage >= 1.0
                        ? AppTheme.success
                        : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressStat(
                      'Raised',
                      '₹${_formatAmount(widget.campaign.collectedAmount)}',
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressStat(
                      'Goal',
                      '₹${_formatAmount(widget.campaign.targetAmount)}',
                      AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressStat(
                      'Remaining',
                      '₹${_formatAmount(remainingAmount)}',
                      remainingAmount <= 0 ? AppTheme.success : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(1)}% of goal reached • ${widget.campaign.contributions.length} contributors',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHostActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campaign Management',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareCampaign(),
                      icon: const Icon(Icons.share),
                      label: const Text('Share Campaign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editCampaign(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.campaign.status == 'active'
                          ? () => _pauseCampaign()
                          : () => _activateCampaign(),
                      icon: Icon(
                        widget.campaign.status == 'active'
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        widget.campaign.status == 'active'
                            ? 'Pause'
                            : 'Activate',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _closeCampaign(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support this Campaign',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Help ${widget.campaign.hostName} reach their goal by contributing to this campaign.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.campaign.status == 'active'
                      ? () => _showContributionDialog()
                      : null,
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('Contribute Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmount('₹100'),
                  _buildQuickAmount('₹500'),
                  _buildQuickAmount('₹1000'),
                  _buildQuickAmount('₹2000'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmount(String amount) {
    return OutlinedButton(
      onPressed: () => _contributeQuickAmount(amount),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(amount),
    );
  }

  Widget _buildContributionsManagement() {
    final gifts = widget.campaign.contributions
        .where((c) => c.type == 'gift')
        .toList();
    final loans = widget.campaign.contributions
        .where((c) => c.type == 'loan')
        .toList();
    final pendingLoans = loans
        .where((c) => c.repaymentStatus == 'pending')
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contributions Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildContributionSummary(
                      'Total',
                      widget.campaign.contributions.length,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  Expanded(
                    child: _buildContributionSummary(
                      'Gifts',
                      gifts.length,
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildContributionSummary(
                      'Loans',
                      loans.length,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildContributionSummary(
                      'Pending',
                      pendingLoans.length,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.campaign.contributions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No contributions yet'),
                  ),
                )
              else
                Column(
                  children: widget.campaign.contributions.map((contribution) {
                    return _buildContributionTile(contribution);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributionSummary(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContributionTile(Contribution contribution) {
    final isLoan = contribution.type == 'loan';
    final isPendingLoan = isLoan && contribution.repaymentStatus == 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLoan
              ? Colors.orange.withValues(alpha: 0.2)
              : AppTheme.success.withValues(alpha: 0.2),
          child: Icon(
            isLoan ? Icons.handshake : Icons.card_giftcard,
            color: isLoan ? Colors.orange : AppTheme.success,
          ),
        ),
        title: Text(contribution.contributorName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${contribution.amount.toStringAsFixed(0)} • ${contribution.type}',
            ),
            if (isLoan && contribution.repaymentDueDate != null)
              Text(
                'Due: ${_formatDate(contribution.repaymentDueDate!)}',
                style: TextStyle(
                  color: isPendingLoan ? Colors.red : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: isLoan
            ? IconButton(
                onPressed: isPendingLoan
                    ? () => _markLoanRepaid(contribution)
                    : null,
                icon: Icon(
                  isPendingLoan
                      ? Icons.check_circle_outline
                      : Icons.check_circle,
                  color: isPendingLoan ? Colors.orange : AppTheme.success,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPublicContributions() {
    final publicContributions = widget.campaign.contributions
        .where((c) => !c.contributorName.contains('Anonymous'))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Supporters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (publicContributions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No public contributions yet'),
                  ),
                )
              else
                Column(
                  children: publicContributions.take(5).map((contribution) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          contribution.contributorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(contribution.contributorName),
                      subtitle: Text(
                        '${contribution.type == 'gift' ? 'Gifted' : 'Loaned'} ₹${contribution.amount.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        _formatDate(contribution.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campaign Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Campaign ID', widget.campaign.id),
              _buildInfoRow('Created', _formatDate(widget.campaign.createdAt)),
              if (widget.campaign.dueDate != null)
                _buildInfoRow(
                  'Due Date',
                  _formatDate(widget.campaign.dueDate!),
                ),
              _buildInfoRow('Status', widget.campaign.status),
            ],
          ),
        ),
      ),
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
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget? _buildHostFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _shareCampaign(),
      icon: const Icon(Icons.share),
      label: const Text('Share'),
      backgroundColor: AppTheme.primaryBlue,
    );
  }

  Widget? _buildContributorFAB() {
    if (widget.campaign.status != 'active') return null;

    return FloatingActionButton.extended(
      onPressed: () => _showContributionDialog(),
      icon: const Icon(Icons.volunteer_activism),
      label: const Text('Contribute'),
      backgroundColor: AppTheme.primaryBlue,
    );
  }

  void _shareCampaign() {
    // TODO: Implement share functionality
    final shareText =
        'Check out this campaign: ${widget.campaign.title}\n\nTarget: ₹${widget.campaign.targetAmount}\nRaised: ₹${widget.campaign.collectedAmount}\n\nHelp me reach my goal!';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign details copied to clipboard!')),
    );
  }

  void _editCampaign() {
    // TODO: Navigate to edit campaign page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit campaign functionality coming soon!')),
    );
  }

  void _pauseCampaign() {
    // TODO: Implement pause campaign
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign paused successfully!')),
    );
  }

  void _activateCampaign() {
    // TODO: Implement activate campaign
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign activated successfully!')),
    );
  }

  void _closeCampaign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Campaign'),
        content: const Text(
          'Are you sure you want to close this campaign? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement close campaign
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Campaign closed successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContributionDialog() {
    showDialog(
      context: context,
      builder: (context) => _ContributionDialog(campaign: widget.campaign),
    );
  }

  void _contributeQuickAmount(String amount) {
    _showContributionDialog();
    // TODO: Pre-fill the contribution dialog with this amount
  }

  void _markLoanRepaid(Contribution loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Loan as Repaid'),
        content: Text(
          'Confirm that ${loan.contributorName} has repaid ₹${loan.amount.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Mark loan as repaid in backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan marked as repaid!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ContributionDialog extends StatefulWidget {
  final Campaign campaign;

  const _ContributionDialog({required this.campaign});

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late final _nameController = TextEditingController(
    text:
        Get.find<AuthController>().userProfile?.name ??
        Get.find<AuthController>().appwriteUser?.name ??
        '',
  );
  final _utrController = TextEditingController();
  String _contributionType = 'gift';
  bool _isAnonymous = false;
  DateTime? _repaymentDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contribute to Campaign'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: (value) =>
                        setState(() => _isAnonymous = value ?? false),
                  ),
                  const Text('Contribute anonymously'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Contribution Type',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioListTile<String>(
                title: const Text('Gift (Non-repayable)'),
                subtitle: const Text('This contribution is a gift'),
                value: 'gift',
                groupValue: _contributionType,
                onChanged: (value) =>
                    setState(() => _contributionType = value ?? 'gift'),
              ),
              RadioListTile<String>(
                title: const Text('Loan (Repayable)'),
                subtitle: const Text('This contribution should be repaid'),
                value: 'loan',
                groupValue: _contributionType,
                onChanged: (value) =>
                    setState(() => _contributionType = value ?? 'gift'),
              ),
              if (_contributionType == 'loan') ...[
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Repayment Due Date'),
                  subtitle: Text(
                    _repaymentDate != null
                        ? '${_repaymentDate!.day}/${_repaymentDate!.month}/${_repaymentDate!.year}'
                        : 'Select due date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectRepaymentDate(),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _utrController,
                decoration: const InputDecoration(
                  labelText: 'UTR Number',
                  helperText: 'Transaction reference from UPI payment',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter UTR number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _submitContribution(),
          child: const Text('Contribute'),
        ),
      ],
    );
  }

  void _selectRepaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _repaymentDate = date);
    }
  }

  void _submitContribution() {
    if (_formKey.currentState!.validate()) {
      if (_contributionType == 'loan' && _repaymentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select repayment due date for loan'),
          ),
        );
        return;
      }

      // TODO: Submit contribution to backend
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution submitted successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _utrController.dispose();
    super.dispose();
  }
}
