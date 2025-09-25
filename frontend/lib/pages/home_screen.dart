import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/responsive_layout.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/contribution_controller.dart';
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
    // Ensure campaigns and contributions are loaded when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final campaignController = Get.find<CampaignController>();
      if (campaignController.campaigns.isEmpty) {
        campaignController.loadCampaigns();
      }

      // Ensure contributions are loaded for dashboard summary
      try {
        if (Get.isRegistered<ContributionController>()) {
          final contributionController = Get.find<ContributionController>();
          // Force reload to ensure we have fresh data
          contributionController.loadUserContributions();
          developer.log(
            'ContributionController: Loading user contributions for home dashboard',
            name: 'HomeScreen',
          );
        } else {
          developer.log(
            'ContributionController: Not registered yet',
            name: 'HomeScreen',
          );
        }
      } catch (e) {
        // ContributionController might not be initialized yet, that's ok
        developer.log(
          'ContributionController not available: $e',
          name: 'HomeScreen',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(
      builder: (campaignController) {
        final allCampaigns = campaignController.campaigns;
        // Filter to only show active campaigns and sort by most recent first
        final activeCampaigns =
            allCampaigns
                .where((campaign) => campaign.status == 'active')
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final displayCampaigns = _showAllCampaigns
            ? activeCampaigns
            : activeCampaigns.take(6).toList();

        return ResponsiveLayout(
          title: 'FriendFund',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddCampaignModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Campaign'),
            tooltip: 'Create New Campaign',
            backgroundColor: AppTheme.primaryViolet,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await campaignController.loadCampaigns();
              // Also refresh contributions
              try {
                if (Get.isRegistered<ContributionController>()) {
                  final contributionController =
                      Get.find<ContributionController>();
                  await contributionController.loadUserContributions();
                }
              } catch (e) {
                developer.log(
                  'Error refreshing contributions: $e',
                  name: 'HomeScreen',
                );
              }
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
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.primaryGradientDecoration.copyWith(
        boxShadow: AppTheme.cardShadowLarge,
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
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Help your friends achieve their goals or get support for yours.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Start your fundraising journey today',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.handshake_rounded,
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
        return GetBuilder<ContributionController>(
          builder: (contributionController) {
            final authController = Get.find<AuthController>();
            final currentUserId = authController.appwriteUser?.$id;

            // Get user's campaigns
            final myCampaigns = campaignController.campaigns
                .where((c) => c.hostId == currentUserId)
                .toList();

            // Calculate totals by getting contributions from the contribution controller
            final totalRaised = myCampaigns.fold<double>(
              0,
              (sum, campaign) => sum + campaign.collectedAmount,
            );

            // Get user's total contributions - now reactive to controller changes
            final userContributions = contributionController.userContributions;
            final totalContributed = userContributions.fold<double>(
              0,
              (sum, contribution) => sum + contribution.amount,
            );
            final contributionCount = userContributions.length;

            // Debug: Log contribution data when dashboard rebuilds
            developer.log(
              'Home Dashboard: Building with $contributionCount contributions, total: ₹$totalContributed',
              name: 'HomeScreen',
            );

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
                                AppTheme.primaryViolet,
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
                                contributionCount.toString(),
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
                                AppTheme.accentViolet,
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
                                    AppTheme.primaryViolet,
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
                                    contributionCount.toString(),
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
                                    AppTheme.accentViolet,
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
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
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
                    childAspectRatio: 0.65,
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
      decoration: AppTheme.cardDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/campaign-details',
            arguments: campaign,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: AppTheme.getStatusChipDecoration(
                        campaign.status,
                      ),
                      child: Text(
                        campaign.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.getStatusColor(campaign.status),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Purpose chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryViolet.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    campaign.purpose,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryViolet,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryViolet.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${(campaign.progressPercentage * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryViolet,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade400,
                        border: Border.all(
                          color: Colors.grey.shade500,
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.5),
                        child: Stack(
                          children: [
                            // Grey background is already set by the parent Container
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: campaign.progressPercentage,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.5),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryViolet,
                                      AppTheme.secondaryViolet,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount info
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Raised',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_formatAmount(campaign.collectedAmount)}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryViolet,
                                    letterSpacing: -0.2,
                                    fontSize: 15,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.primaryViolet.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Goal',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_formatAmount(campaign.targetAmount)}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                    fontSize: 15,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                  AppTheme.primaryViolet,
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
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Explore',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: color, size: 12),
                  ],
                ),
              ],
            ),
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
