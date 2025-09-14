import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/app_bar_with_menu.dart';
import '../components/campaign_card.dart';
import '../components/custom_fab.dart';
import '../controllers/campaign_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final campaignController = Get.find<CampaignController>();

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'FriendFund'),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (campaignController.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.teal),
                SizedBox(height: 16),
                Text('Loading campaigns...'),
              ],
            ),
          );
        }

        if (campaignController.campaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No campaigns available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to create a campaign!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/add-campaign'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return RefreshIndicator(
              onRefresh: () => campaignController.loadCampaigns(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    childAspectRatio: isMobile ? 1.2 : 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: campaignController.campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaignController.campaigns[index];
                    return CampaignCard(
                      title: campaign.title,
                      purpose: campaign.purpose,
                      collected: campaign.collectedAmount,
                      target: campaign.targetAmount,
                      onTap: () {
                        campaignController.getCampaignDetails(campaign.id);
                        Get.toNamed('/campaign-details');
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: CustomFAB(
        onPressed: () => Get.toNamed('/add-campaign'),
        tooltip: 'Add Campaign',
      ),
    );
  }
}
