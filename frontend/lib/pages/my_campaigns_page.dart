import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/app_bar_with_menu.dart';
import '../components/campaign_card.dart';
import '../controllers/campaign_controller.dart';

class MyCampaignsPage extends StatelessWidget {
  const MyCampaignsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final campaignController = Get.find<CampaignController>();

    // Load user campaigns when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      campaignController.loadMyCampaigns();
    });

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'My Campaigns'),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (campaignController.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.teal),
                SizedBox(height: 16),
                Text('Loading your campaigns...'),
              ],
            ),
          );
        }

        if (campaignController.myCampaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No campaigns created yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first campaign to start raising funds',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/add-campaign'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => campaignController.loadMyCampaigns(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with stats
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Campaigns',
                              campaignController.myCampaigns.length.toString(),
                              Icons.campaign,
                            ),
                            _buildStatItem(
                              'Active',
                              campaignController.myCampaigns
                                  .where((c) => c.status == 'active')
                                  .length
                                  .toString(),
                              Icons.trending_up,
                            ),
                            _buildStatItem(
                              'Completed',
                              campaignController.myCampaigns
                                  .where((c) => c.status == 'closed')
                                  .length
                                  .toString(),
                              Icons.check_circle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campaigns Grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          childAspectRatio: isMobile ? 1.2 : 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: campaignController.myCampaigns.length,
                        itemBuilder: (context, index) {
                          final campaign =
                              campaignController.myCampaigns[index];
                          return CampaignCard(
                            title: campaign.title,
                            purpose: campaign.purpose,
                            collected: campaign.collectedAmount,
                            target: campaign.targetAmount,
                            onTap: () {
                              campaignController.getCampaignDetails(
                                campaign.id,
                              );
                              Get.toNamed('/campaign-details');
                            },
                            isOwner: true, // This is the user's campaign
                            status: campaign.status,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-campaign'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
