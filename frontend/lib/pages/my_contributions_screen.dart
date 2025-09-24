import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/responsive_layout.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';
import '../controllers/contribution_controller.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/loan_repayment_modal.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ContributionController _contributionController =
      Get.find<ContributionController>();
  final CampaignController _campaignController = Get.find<CampaignController>();
  final AuthController _authController = Get.find<AuthController>();

  List<Contribution> _allContributions = [];
  List<Contribution> _loansToRepay = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    if (!_authController.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to view your contributions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _contributionController.loadUserContributions();
      final loansToRepay = await _contributionController.loadLoansToRepay();
      setState(() {
        _allContributions = _contributionController.userContributions
          ..sort((a, b) => b.date.compareTo(a.date));
        _loansToRepay = loansToRepay..sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contributions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshContributions() async {
    await _loadContributions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ResponsiveLayout(
        title: 'My Contributions',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return ResponsiveLayout(
        title: 'My Contributions',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshContributions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter contributions by type and sort by most recent first
    final gifts = _allContributions.where((c) => c.type == 'gift').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final loansGiven = _allContributions.where((c) => c.type == 'loan').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final loansToRepay = _loansToRepay
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate summary stats
    final totalGifted = gifts.fold<double>(0, (sum, c) => sum + c.amount);
    final totalLoaned = loansGiven.fold<double>(0, (sum, c) => sum + c.amount);
    final totalToRepay = loansToRepay.fold<double>(
      0,
      (sum, c) => sum + c.amount,
    );

    return ResponsiveLayout(
      title: 'My Contributions',
      child: Column(
        children: [
          _buildSummarySection(context, totalGifted, totalLoaned, totalToRepay),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.card_giftcard_outlined, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          'Gifts (${gifts.length})',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.handshake_outlined, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          'Loans (${loansGiven.length})',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            if (loansToRepay.isNotEmpty)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    loansToRepay.length.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Repay (${loansToRepay.length})',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
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
                _buildLoansGivenList(loansGiven),
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
                child: _buildSummaryItem(
                  context,
                  'Total Gifted',
                  '₹${totalGifted.toStringAsFixed(0)}',
                  Icons.card_giftcard_outlined,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Total Loaned',
                  '₹${totalLoaned.toStringAsFixed(0)}',
                  Icons.handshake_outlined,
                  AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'To Repay',
                  '₹${totalToRepay.toStringAsFixed(0)}',
                  Icons.schedule,
                  totalToRepay > 0 ? Colors.orange : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 110, // Fixed height to ensure all cards are the same size
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
      onRefresh: _refreshContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contributions.length,
        itemBuilder: (context, index) {
          final contribution = contributions[index];
          return _buildEnhancedContributionCard(contribution);
        },
      ),
    );
  }

  Widget _buildLoansGivenList(List<Contribution> loansGiven) {
    if (loansGiven.isEmpty) {
      return _buildEmptyState('No loans given yet');
    }

    return RefreshIndicator(
      onRefresh: _refreshContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loansGiven.length,
        itemBuilder: (context, index) {
          final loan = loansGiven[index];
          return _buildLoanGivenCard(loan);
        },
      ),
    );
  }

  Widget _buildLoanGivenCard(Contribution loan) {
    final bool isPending = loan.repaymentStatus == 'pending';
    final bool isOverdue =
        loan.repaymentDueDate != null &&
        loan.repaymentDueDate!.isBefore(DateTime.now()) &&
        isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.handshake_outlined,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Given',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getCampaignName(loan.campaignId),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${loan.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPending
                            ? (isOverdue ? Colors.red : Colors.orange)
                            : AppTheme.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPending
                            ? (isOverdue ? 'Overdue' : 'Pending')
                            : 'Repaid',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${_formatDate(loan.date)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (loan.repaymentDueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${_formatDueDate(loan.repaymentDueDate!)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isOverdue
                                    ? Colors.red
                                    : AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isPending) ...[
                  ElevatedButton(
                    onPressed: () => _markLoanAsRepaid(loan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Mark Repaid',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markLoanAsRepaid(Contribution loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Loan as Repaid'),
        content: Text(
          'Confirm that you have received repayment of ₹${loan.amount.toStringAsFixed(0)} for this loan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _contributionController.updateContributionStatus(
          loan.id,
          {'repaymentStatus': 'repaid'},
        );

        if (success) {
          await _refreshContributions();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loan marked as repaid successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark loan as repaid: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _repayLoan(Contribution loan) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => LoanRepaymentModal(loanContribution: loan),
      );

      if (result == true) {
        // Refresh the contributions to reflect the updated status
        await _refreshContributions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening repayment modal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoansToRepayList(List<Contribution> loansToRepay) {
    if (loansToRepay.isEmpty) {
      return _buildLoansToRepayEmptyState();
    }

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
      onRefresh: _refreshContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loansToRepay.length,
        itemBuilder: (context, index) {
          final loan = loansToRepay[index];
          return _buildLoanRepaymentCard(loan);
        },
      ),
    );
  }

  Widget _buildLoanRepaymentCard(Contribution loan) {
    final daysUntilDue = loan.repaymentDueDate != null
        ? loan.repaymentDueDate!.difference(DateTime.now()).inDays
        : null;
    final isOverdue = daysUntilDue != null && daysUntilDue < 0;
    final isNearDue =
        daysUntilDue != null && daysUntilDue <= 7 && daysUntilDue >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 4 : 2,
      child: Container(
        decoration: isOverdue
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and amount
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isOverdue ? Colors.red : AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount to Repay',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? Colors.red
                                    : AppTheme.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Loan received from ${loan.contributorName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${loan.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? Colors.red
                                  : AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red
                              : isNearDue
                              ? Colors.orange
                              : AppTheme.success.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isOverdue
                              ? 'OVERDUE'
                              : isNearDue
                              ? 'DUE SOON'
                              : 'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Loan details section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loan Details',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Campaign:',
                      _getCampaignName(loan.campaignId),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Loan Amount:',
                      '₹${loan.amount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Received Date:', _formatDate(loan.date)),
                    if (loan.repaymentDueDate != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Due Date:',
                        _formatDueDate(loan.repaymentDueDate!),
                        isImportant: isOverdue || isNearDue,
                      ),
                      if (daysUntilDue != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Days Remaining:',
                          isOverdue
                              ? 'Overdue by ${(-daysUntilDue)} days'
                              : '$daysUntilDue days',
                          isImportant: isOverdue || isNearDue,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Payment instructions or warning
              if (isOverdue || isNearDue) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOverdue ? Colors.red : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        color: isOverdue ? Colors.red : Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverdue
                                  ? 'Payment Overdue!'
                                  : 'Payment Due Soon!',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? Colors.red
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOverdue
                                  ? 'This loan is overdue. Please repay ₹${loan.amount.toStringAsFixed(0)} to ${loan.contributorName} immediately.'
                                  : 'This loan is due soon. Please prepare ₹${loan.amount.toStringAsFixed(0)} for repayment to ${loan.contributorName}.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? Colors.red
                                        : Colors.orange,
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: AppTheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Remember to repay ₹${loan.amount.toStringAsFixed(0)} to ${loan.contributorName} by ${loan.repaymentDueDate != null ? _formatDueDate(loan.repaymentDueDate!) : 'the agreed date'}.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Repay Loan Button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _repayLoan(loan),
                  icon: const Icon(Icons.payment),
                  label: Text(
                    'Repay ₹${loan.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue
                        ? Colors.red
                        : isNearDue
                        ? Colors.orange
                        : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isImportant ? Colors.red : AppTheme.textPrimary,
              fontWeight: isImportant ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedContributionCard(Contribution contribution) {
    final isLoan = contribution.type == 'loan';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLoan
                        ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                        : AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLoan
                        ? Icons.handshake_outlined
                        : Icons.card_giftcard_outlined,
                    color: isLoan ? AppTheme.primaryBlue : AppTheme.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoan ? 'Loan' : 'Gift',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getCampaignName(contribution.campaignId),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${contribution.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLoan ? AppTheme.primaryBlue : AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Date: ${_formatDate(contribution.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isLoan && contribution.repaymentDueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Repayment Due: ${_formatDueDate(contribution.repaymentDueDate!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/home'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Start Contributing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansToRepayEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Loans to Repay! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You currently have no outstanding loans to repay.\n\nLoans appear here when contributors give loans to your campaigns that need to be repaid.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(height: 8),
                Text(
                  'How Loans Work',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone contributes to your campaigns as a "loan" instead of a "gift", those amounts will appear here as loans you need to repay to the contributor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/home'),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('View My Campaigns'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays < 0) {
      final overdueDays = (-difference.inDays);
      if (overdueDays == 1) {
        return 'Overdue by 1 day';
      } else {
        return 'Overdue by $overdueDays days';
      }
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getCampaignName(String campaignId) {
    try {
      final campaign = _campaignController.campaigns.firstWhere(
        (campaign) => campaign.id == campaignId,
      );
      return campaign.title;
    } catch (e) {
      // If campaign not found, return the ID with a fallback label
      return 'Campaign ID: $campaignId';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
