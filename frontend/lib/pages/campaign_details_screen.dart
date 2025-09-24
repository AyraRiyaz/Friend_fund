import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../widgets/responsive_layout.dart';
import '../controllers/auth_controller.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/contribution_controller.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';
import '../widgets/edit_campaign_modal.dart';
import '../widgets/campaign_qr_widget.dart';
import '../widgets/contribution_modal.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  final CampaignController _campaignController = Get.find<CampaignController>();
  final ContributionController _contributionController =
      Get.find<ContributionController>();
  late Campaign _currentCampaign;
  List<Contribution> _contributions = [];
  bool _isLoadingContributions = false;
  bool _showAllContributions = false;

  @override
  void initState() {
    super.initState();
    _currentCampaign = widget.campaign;
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoadingContributions = true;
    });

    try {
      final contributions = await _contributionController
          .loadCampaignContributions(_currentCampaign.id);
      setState(() {
        _contributions = contributions;
        // Update the campaign with the latest contributions
        _currentCampaign = _currentCampaign.copyWith(
          contributions: contributions,
        );
      });
    } catch (e) {
      print('Error loading contributions: $e');
    } finally {
      setState(() {
        _isLoadingContributions = false;
      });
    }
  }

  Future<void> _refreshCampaignData() async {
    await _loadContributions();
  }

  bool get isMyOwnCampaign {
    final authController = Get.find<AuthController>();
    return _currentCampaign.hostId == authController.appwriteUser?.$id;
  }

  bool get canEdit {
    return isMyOwnCampaign && _currentCampaign.status.toLowerCase() != 'closed';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Campaign Details',
      child: SingleChildScrollView(
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
                  _currentCampaign.title,
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
              _currentCampaign.purpose,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentCampaign.description,
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
                'Hosted by ${_currentCampaign.hostName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(_currentCampaign.createdAt),
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

    switch (_currentCampaign.status.toLowerCase()) {
      case 'active':
        chipColor = AppTheme.success;
        statusText = 'Active';
        break;
      case 'closed':
        chipColor = Colors.grey;
        statusText = 'Closed';
        break;
      case 'paused':
      case 'inactive':
        chipColor = Colors.orange;
        statusText = 'Paused';
        break;
      default:
        chipColor = AppTheme.primaryBlue;
        statusText = _currentCampaign.status;
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
    final progressPercentage = _currentCampaign.progressPercentage;
    final remainingAmount =
        _currentCampaign.targetAmount - _currentCampaign.collectedAmount;

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
                      '₹${_formatAmount(_currentCampaign.collectedAmount)}',
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressStat(
                      'Goal',
                      '₹${_formatAmount(_currentCampaign.targetAmount)}',
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
                '${(progressPercentage * 100).toStringAsFixed(1)}% of goal reached • ${_currentCampaign.contributions.length} contributors',
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
    final isClosed = _currentCampaign.status.toLowerCase() == 'closed';
    final isActive = _currentCampaign.status.toLowerCase() == 'active';
    final isPaused =
        _currentCampaign.status.toLowerCase() == 'inactive' ||
        _currentCampaign.status.toLowerCase() == 'paused';

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
              if (!isClosed) ...[
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
                        onPressed: isActive
                            ? () => _pauseCampaign()
                            : isPaused
                            ? () => _activateCampaign()
                            : null,
                        icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                        label: Text(isActive ? 'Pause' : 'Activate'),
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
              ] else ...[
                // Show only share button for closed campaigns
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This campaign has been closed and cannot be edited or modified.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareCampaign(),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Campaign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
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

  Widget _buildContributeSection() {
    final isClosed = _currentCampaign.status.toLowerCase() == 'closed';
    final isActive = _currentCampaign.status.toLowerCase() == 'active';

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
              if (isClosed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This campaign has been closed and is no longer accepting contributions.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isActive) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This campaign is currently paused and not accepting new contributions.',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Help ${_currentCampaign.hostName} reach their goal by contributing to this campaign.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showContributionDialog(),
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text('Contribute Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildContributionsManagement() {
    if (_isLoadingContributions) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Contributions Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Text('Loading contributions...'),
              ],
            ),
          ),
        ),
      );
    }

    final gifts = _currentCampaign.contributions
        .where((c) => c.type == 'gift')
        .toList();
    final loans = _currentCampaign.contributions
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contributions Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshCampaignData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh contributions',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildContributionSummary(
                      'Total',
                      _currentCampaign.contributions.length,
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
              if (_currentCampaign.contributions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No contributions yet'),
                  ),
                )
              else
                Column(
                  children: [
                    // Show contributions based on _showAllContributions state
                    ...(_showAllContributions
                            ? _getAllContributionsSorted()
                            : _getMostRecentContributions(3))
                        .map((contribution) {
                          return _buildContributionTile(contribution);
                        })
                        .toList(),
                    if (_currentCampaign.contributions.length > 3) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllContributions = !_showAllContributions;
                            });
                          },
                          icon: Icon(
                            _showAllContributions
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          label: Text(
                            _showAllContributions
                                ? 'Show Less'
                                : 'View All ${_currentCampaign.contributions.length} Contributions',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    final isAnonymous =
        contribution.isAnonymous || contribution.contributorId == null;

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
        title: Row(
          children: [
            Expanded(child: Text(contribution.contributorName)),
            if (isAnonymous)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Guest',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
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
    // Show all contributions, but display anonymous ones differently
    final allContributions = _currentCampaign.contributions.toList();

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
              if (allContributions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No contributions yet'),
                  ),
                )
              else
                Column(
                  children: allContributions.take(5).map((contribution) {
                    final isAnonymous =
                        contribution.isAnonymous ||
                        contribution.contributorId == null;
                    final displayName = isAnonymous
                        ? 'Anonymous Supporter'
                        : contribution.contributorName;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          isAnonymous ? Icons.person_outline : Icons.person,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(displayName)),
                          if (isAnonymous)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Guest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
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
              _buildInfoRow('Created', _formatDate(_currentCampaign.createdAt)),
              if (_currentCampaign.dueDate != null)
                _buildInfoRow(
                  'Due Date',
                  _formatDate(_currentCampaign.dueDate!),
                ),
              _buildInfoRow('Status', _currentCampaign.status),
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
    if (_currentCampaign.status.toLowerCase() != 'active') return null;

    return FloatingActionButton.extended(
      onPressed: () => _showContributionDialog(),
      icon: const Icon(Icons.volunteer_activism),
      label: const Text('Contribute'),
      backgroundColor: AppTheme.primaryBlue,
    );
  }

  void _shareCampaign() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: CampaignQRWidget(campaign: _currentCampaign),
        ),
      ),
    );
  }

  void _editCampaign() {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Closed campaigns cannot be edited!')),
      );
      return;
    }

    showEditCampaignModal(context, _currentCampaign);
  }

  void _pauseCampaign() {
    if (!canEdit) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Campaign'),
        content: const Text(
          'Are you sure you want to pause this campaign? It will no longer accept new contributions until reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _campaignController.pauseCampaign(
                _currentCampaign.id,
              );
              if (success) {
                setState(() {
                  _currentCampaign = _currentCampaign.copyWith(
                    status: 'inactive',
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaign paused successfully!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _activateCampaign() {
    if (!canEdit) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Campaign'),
        content: const Text(
          'Are you sure you want to activate this campaign? It will start accepting contributions again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _campaignController.activateCampaign(
                _currentCampaign.id,
              );
              if (success) {
                setState(() {
                  _currentCampaign = _currentCampaign.copyWith(
                    status: 'active',
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaign activated successfully!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _closeCampaign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Campaign'),
        content: const Text(
          'Are you sure you want to close this campaign? This action cannot be undone. The campaign will no longer accept contributions and cannot be edited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _campaignController.closeCampaign(
                _currentCampaign.id,
              );
              if (success) {
                setState(() {
                  _currentCampaign = _currentCampaign.copyWith(
                    status: 'closed',
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaign closed successfully!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContributionDialog({bool isFromQrCode = false}) {
    // Show the contribution modal
    showDialog(
      context: context,
      builder: (context) => EnhancedContributionModal(
        campaignId: _currentCampaign.id,
        isFromQrCode: isFromQrCode,
      ),
    ).then((result) {
      // Refresh contributions after modal closes
      if (result == true) {
        _refreshCampaignData();
      }
    });
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

  List<Contribution> _getMostRecentContributions(int count) {
    final sortedContributions = List<Contribution>.from(
      _currentCampaign.contributions,
    );
    sortedContributions.sort((a, b) => b.date.compareTo(a.date));
    return sortedContributions.take(count).toList();
  }

  List<Contribution> _getAllContributionsSorted() {
    final sortedContributions = List<Contribution>.from(
      _currentCampaign.contributions,
    );
    sortedContributions.sort((a, b) => b.date.compareTo(a.date));
    return sortedContributions;
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
