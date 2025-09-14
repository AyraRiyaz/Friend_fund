import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../widgets/campaign_card.dart';
import '../data/dummy_data.dart';
import '../theme/app_theme.dart';

class MyCampaignsScreen extends StatelessWidget {
  const MyCampaignsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myCampaigns = DummyData.getMyCampaigns();

    return MainLayout(
      title: 'My Campaigns',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-campaign'),
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
      child: myCampaigns.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
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
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Campaigns Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first campaign to start raising funds for your goals.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
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
