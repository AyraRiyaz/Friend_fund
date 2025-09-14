import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../widgets/contribution_card.dart';
import '../data/dummy_data.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({Key? key}) : super(key: key);

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
    final myContributions = DummyData.getMyContributions();
    final gifts = myContributions.where((c) => c.type == 'gift').toList();
    final loansGiven = myContributions.where((c) => c.type == 'loan').toList();
    final loansToRepay = DummyData.getLoansToRepay();

    return MainLayout(
      title: 'My Contributions',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: [
                Tab(
                  text: 'Gifts (${gifts.length})',
                  icon: const Icon(Icons.card_giftcard_outlined),
                ),
                Tab(
                  text: 'Loans Given (${loansGiven.length})',
                  icon: const Icon(Icons.handshake_outlined),
                ),
                Tab(
                  text: 'To Repay (${loansToRepay.length})',
                  icon: const Icon(Icons.schedule),
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
          final campaign = DummyData.allCampaigns.firstWhere(
            (c) => c.id == contribution.campaignId,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContributionCard(
              contribution: contribution,
              showCampaignName: true,
              campaignTitle: campaign.title,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoansToRepayList(List<Contribution> loansToRepay) {
    if (loansToRepay.isEmpty) {
      return _buildEmptyState('No loans to repay');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loansToRepay.length,
        itemBuilder: (context, index) {
          final loan = loansToRepay[index];
          final campaign = DummyData.allCampaigns.firstWhere(
            (c) => c.id == loan.campaignId,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContributionCard(
              contribution: loan,
              showCampaignName: true,
              campaignTitle: campaign.title,
              onMarkRepaid: () => _markAsRepaid(loan),
            ),
          );
        },
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
            Icon(Icons.inbox_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start contributing to campaigns to see them here.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
