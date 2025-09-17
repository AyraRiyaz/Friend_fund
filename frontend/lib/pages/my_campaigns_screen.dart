import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/app_bar_with_menu.dart';
import '../widgets/campaign_card.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/add_campaign_modal.dart';

class MyCampaignsScreen extends StatelessWidget {
  const MyCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(
      builder: (campaignController) {
        final authController = Get.find<AuthController>();
        final currentUserId = authController.appwriteUser?.$id;

        final myCampaigns = campaignController.campaigns
            .where((c) => c.hostId == currentUserId)
            .toList();

        return Scaffold(
          appBar: const AppBarWithMenu(title: 'My Campaigns'),
          drawer: const AppDrawer(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddCampaignModal(context),
            icon: const Icon(Icons.add),
            label: const Text('New Campaign'),
          ),
          body: myCampaigns.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    await campaignController.loadCampaigns();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = myCampaigns[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CampaignCard(
                          campaign: campaign,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/campaign-details',
                            arguments: campaign,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 80,
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Campaigns Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first campaign to start raising funds for your goals.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-campaign'),
              icon: const Icon(Icons.add),
              label: const Text('Create Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}
