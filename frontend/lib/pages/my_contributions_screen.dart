import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real API calls when contributions endpoint is implemented
    final gifts = <Contribution>[];
    final loansGiven = <Contribution>[];
    final loansToRepay = <Contribution>[];

    // Calculate summary stats
    final totalGifted = gifts.fold<double>(0, (sum, c) => sum + c.amount);
    final totalLoaned = loansGiven.fold<double>(0, (sum, c) => sum + c.amount);
    final totalToRepay = loansToRepay.fold<double>(
      0,
      (sum, c) => sum + c.amount,
    );

    return MainLayout(
      title: 'My Contributions',
      child: Column(
        children: [
          _buildSummarySection(context, totalGifted, totalLoaned, totalToRepay),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard_outlined),
                      const SizedBox(height: 4),
                      Text('Gifts (${gifts.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.handshake_outlined),
                      const SizedBox(height: 4),
                      Text('Loans Given (${loansGiven.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          const Icon(Icons.schedule),
                          if (loansToRepay.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  loansToRepay.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('To Repay (${loansToRepay.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContributionsList(gifts, 'No gifts made yet'),
                _buildContributionsList(loansGiven, 'No loans given yet'),
                _buildLoansToRepayList(loansToRepay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    double totalGifted,
    double totalLoaned,
    double totalToRepay,
  ) {
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
          Text(
            'Your Contribution Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  context,
                  'Total Gifted',
                  '₹${_formatAmount(totalGifted)}',
                  AppTheme.success,
                  Icons.card_giftcard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  context,
                  'Total Loaned',
                  '₹${_formatAmount(totalLoaned)}',
                  Colors.orange,
                  Icons.handshake,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStat(
                  context,
                  'To Repay',
                  '₹${_formatAmount(totalToRepay)}',
                  totalToRepay > 0 ? Colors.red : AppTheme.textSecondary,
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContributionsList(
    List<Contribution> contributions,
    String emptyMessage,
  ) {
    if (contributions.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contributions.length,
        itemBuilder: (context, index) {
          final contribution = contributions[index];
          // TODO: Get campaign details from API
          final campaign = Campaign(
            id: contribution.campaignId,
            title: 'Campaign Title',
            description: 'Campaign Description',
            targetAmount: 0,
            collectedAmount: 0,
            hostId: '',
            hostName: '',
            purpose: '',
            status: 'active',
            createdAt: DateTime.now(),
            contributions: [],
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEnhancedContributionCard(contribution, campaign),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedContributionCard(
    Contribution contribution,
    Campaign campaign,
  ) {
    final isLoan = contribution.type == 'loan';
    final isOverdue =
        isLoan &&
        contribution.repaymentDueDate != null &&
        contribution.repaymentDueDate!.isBefore(DateTime.now()) &&
        contribution.repaymentStatus == 'pending';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/campaign-details',
          arguments: campaign,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isLoan
                        ? Colors.orange.withValues(alpha: 0.2)
                        : AppTheme.success.withValues(alpha: 0.2),
                    child: Icon(
                      isLoan ? Icons.handshake : Icons.card_giftcard,
                      color: isLoan ? Colors.orange : AppTheme.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${campaign.hostName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLoan
                          ? Colors.orange.withValues(alpha: 0.1)
                          : AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${contribution.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLoan ? Colors.orange : AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isLoan ? Icons.handshake : Icons.card_giftcard,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLoan ? 'Loan' : 'Gift',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(contribution.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (isLoan && contribution.repaymentDueDate != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue
                            ? 'OVERDUE'
                            : 'Due: ${_formatDate(contribution.repaymentDueDate!)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : Colors.blue,
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

  Widget _buildLoansToRepayList(List<Contribution> loansToRepay) {
    if (loansToRepay.isEmpty) {
      return _buildEmptyState(
        'No loans to repay',
        subtitle: 'Great! You have no pending loan repayments.',
        icon: Icons.check_circle_outline,
        iconColor: AppTheme.success,
      );
    }

    // Sort by due date (overdue first)
    loansToRepay.sort((a, b) {
      if (a.repaymentDueDate == null && b.repaymentDueDate == null) return 0;
      if (a.repaymentDueDate == null) return 1;
      if (b.repaymentDueDate == null) return -1;

      final now = DateTime.now();
      final aOverdue = a.repaymentDueDate!.isBefore(now);
      final bOverdue = b.repaymentDueDate!.isBefore(now);

      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      return a.repaymentDueDate!.compareTo(b.repaymentDueDate!);
    });

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loansToRepay.length,
        itemBuilder: (context, index) {
          final loan = loansToRepay[index];
          // TODO: Get campaign details from API
          final campaign = Campaign(
            id: loan.campaignId,
            title: 'Campaign Title',
            description: 'Campaign Description',
            targetAmount: 0,
            collectedAmount: 0,
            hostId: '',
            hostName: '',
            purpose: '',
            status: 'active',
            createdAt: DateTime.now(),
            contributions: [],
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoanRepaymentCard(loan, campaign),
          );
        },
      ),
    );
  }

  Widget _buildLoanRepaymentCard(Contribution loan, Campaign campaign) {
    final isOverdue =
        loan.repaymentDueDate != null &&
        loan.repaymentDueDate!.isBefore(DateTime.now());
    final daysUntilDue = loan.repaymentDueDate != null
        ? loan.repaymentDueDate!.difference(DateTime.now()).inDays
        : null;

    return Card(
      elevation: isOverdue ? 4 : 2,
      child: Container(
        decoration: isOverdue
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 2,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isOverdue
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.schedule,
                      color: isOverdue ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan from ${loan.contributorName}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For: ${campaign.title}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${loan.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (loan.repaymentDueDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.1)
                        : daysUntilDue != null && daysUntilDue <= 3
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.error_outline : Icons.schedule,
                        size: 16,
                        color: isOverdue
                            ? Colors.red
                            : daysUntilDue != null && daysUntilDue <= 3
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOverdue
                              ? 'Overdue by ${(-daysUntilDue!)} days'
                              : daysUntilDue == 0
                              ? 'Due today'
                              : daysUntilDue == 1
                              ? 'Due tomorrow'
                              : 'Due in $daysUntilDue days (${_formatDate(loan.repaymentDueDate!)})',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isOverdue
                                ? Colors.red
                                : daysUntilDue != null && daysUntilDue <= 3
                                ? Colors.orange
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactLender(loan),
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('Contact'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsRepaid(loan),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Repaid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildEmptyState(
    String message, {
    String? subtitle,
    IconData? icon,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 80,
              color: iconColor ?? AppTheme.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              child: const Text('Explore Campaigns'),
            ),
          ],
        ),
      ),
    );
  }

  void _contactLender(Contribution loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Lender'),
        content: Text(
          'Contact ${loan.contributorName} regarding the loan repayment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement contact functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact feature coming soon!')),
              );
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  void _markAsRepaid(Contribution loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Repaid'),
        content: Text(
          'Confirm that you have repaid ₹${loan.amount.toStringAsFixed(0)} to ${loan.contributorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // In a real app, this would update via API
                // For demo, we'll just show a success message
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marked as repaid successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
