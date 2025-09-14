import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../widgets/campaign_card.dart';
import '../data/dummy_data.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recentCampaigns = DummyData.allCampaigns.take(6).toList();

    return MainLayout(
      title: 'FriendFund',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-campaign'),
        icon: const Icon(Icons.add),
        label: const Text('Add Campaign'),
        tooltip: 'Create New Campaign',
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 24),
              Text(
                'Recent Campaigns',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 3
                      : constraints.maxWidth > 800
                      ? 2
                      : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: recentCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = recentCampaigns[index];
                      return CampaignCard(
                        campaign: campaign,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/campaign-details',
                          arguments: campaign,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${DummyData.currentUser.name.split(' ').first}! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help your friends achieve their goals or get support for yours.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-campaign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Start a Campaign'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final myCampaigns = DummyData.getMyCampaigns();
    final myContributions = DummyData.getMyContributions();
    final totalRaised = myCampaigns.fold<double>(
      0,
      (sum, campaign) => sum + campaign.collectedAmount,
    );
    final totalContributed = myContributions.fold<double>(
      0,
      (sum, contribution) => sum + contribution.amount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          // Show 4 cards in a single row on wide screens
          return Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Campaigns Created',
                  myCampaigns.length.toString(),
                  Icons.campaign_outlined,
                  AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Raised',
                  '₹${_formatAmount(totalRaised)}',
                  Icons.trending_up,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Contributions Made',
                  myContributions.length.toString(),
                  Icons.favorite_outline,
                  AppTheme.secondaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Contributed',
                  '₹${_formatAmount(totalContributed)}',
                  Icons.handshake_outlined,
                  AppTheme.accentBlue,
                ),
              ),
            ],
          );
        } else {
          // Show 2x2 grid on smaller screens
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Campaigns Created',
                      myCampaigns.length.toString(),
                      Icons.campaign_outlined,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Raised',
                      '₹${_formatAmount(totalRaised)}',
                      Icons.trending_up,
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Contributions Made',
                      myContributions.length.toString(),
                      Icons.favorite_outline,
                      AppTheme.secondaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Contributed',
                      '₹${_formatAmount(totalContributed)}',
                      Icons.handshake_outlined,
                      AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
}
