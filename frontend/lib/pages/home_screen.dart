import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/app_bar_with_menu.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/add_campaign_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllCampaigns = false;

  @override
  void initState() {
    super.initState();
    // Ensure campaigns are loaded when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final campaignController = Get.find<CampaignController>();
      if (campaignController.campaigns.isEmpty) {
        campaignController.loadCampaigns();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(
      builder: (campaignController) {
        final allCampaigns = campaignController.campaigns;
        // Filter to only show active campaigns
        final activeCampaigns = allCampaigns
            .where((campaign) => campaign.status == 'active')
            .toList();
        final displayCampaigns = _showAllCampaigns
            ? activeCampaigns
            : activeCampaigns.take(6).toList();

        return Scaffold(
          appBar: const AppBarWithMenu(title: 'FriendFund'),
          drawer: const AppDrawer(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddCampaignModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Campaign'),
            tooltip: 'Create New Campaign',
            backgroundColor: AppTheme.primaryBlue,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await campaignController.loadCampaigns();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context),
                  const SizedBox(height: 20),
                  _buildDashboardSummary(context),
                  const SizedBox(height: 24),
                  _buildRecentCampaigns(
                    context,
                    displayCampaigns,
                    activeCampaigns,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GetBuilder<AuthController>(
                      builder: (authController) {
                        final userName =
                            authController.userProfile?.name ??
                            authController.appwriteUser?.name ??
                            'Friend';
                        return Text(
                          'Welcome back, ${userName.split(' ').first}! 👋',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help your friends achieve their goals or get support for yours.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(BuildContext context) {
    return GetBuilder<CampaignController>(
      builder: (campaignController) {
        final authController = Get.find<AuthController>();
        final currentUserId = authController.appwriteUser?.$id;

        // Get user's campaigns
        final myCampaigns = campaignController.campaigns
            .where((c) => c.hostId == currentUserId)
            .toList();

        // Calculate totals (we'll need contribution data later)
        final totalRaised = myCampaigns.fold<double>(
          0,
          (sum, campaign) => sum + campaign.collectedAmount,
        );
        final totalContributed = 0.0; // TODO: Get from contributions API
        final activeCampaigns = campaignController.campaigns
            .where((c) => c.status == 'active')
            .length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Active Campaigns',
                            activeCampaigns.toString(),
                            Icons.campaign,
                            AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Raised',
                            '₹${_formatAmount(totalRaised)}',
                            Icons.trending_up,
                            AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Contributions',
                            '0', // TODO: Get from contributions API
                            Icons.favorite,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Given',
                            '₹${_formatAmount(totalContributed)}',
                            Icons.handshake,
                            AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                'Active Campaigns',
                                activeCampaigns.toString(),
                                Icons.campaign,
                                AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
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
                              child: _buildSummaryCard(
                                context,
                                'Contributions',
                                '0', // TODO: Get from contributions API
                                Icons.favorite,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                'Total Given',
                                '₹${_formatAmount(totalContributed)}',
                                Icons.handshake,
                                AppTheme.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCampaigns(
    BuildContext context,
    List<dynamic> recentCampaigns,
    List<dynamic> allActiveCampaigns,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAllCampaigns
                    ? 'All Active Campaigns'
                    : 'Recent Active Campaigns',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Only show the button if there are more than 6 active campaigns
              if (allActiveCampaigns.length > 6)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllCampaigns = !_showAllCampaigns;
                    });
                  },
                  child: Text(_showAllCampaigns ? 'Show Less' : 'View All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 900 ? 4 : 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: recentCampaigns.length,
                  itemBuilder: (context, index) {
                    return _buildCampaignCard(context, recentCampaigns[index]);
                  },
                );
              } else {
                // Mobile: 2-column grid
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: recentCampaigns.length,
                  itemBuilder: (context, index) {
                    return _buildCampaignCard(context, recentCampaigns[index]);
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, dynamic campaign) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/campaign-details',
            arguments: campaign,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  campaign.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Purpose
                Text(
                  campaign.purpose,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Progress bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey[200],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: campaign.progressPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Amount info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${_formatAmount(campaign.collectedAmount)}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                  fontSize: 11,
                                ),
                          ),
                          Text(
                            'of ₹${_formatAmount(campaign.targetAmount)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(campaign.progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'My Campaigns',
                  'View and manage your campaigns',
                  Icons.campaign,
                  AppTheme.primaryBlue,
                  () => Navigator.pushNamed(context, '/my-campaigns'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'My Contributions',
                  'Track your contributions',
                  Icons.favorite,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/my-contributions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
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
