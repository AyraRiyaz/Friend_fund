import 'package:flutter/material.dart';

import '../components/app_bar_with_menu.dart';
import '../components/campaign_card.dart';
import '../components/custom_fab.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example campaigns
    final campaigns = [
      {
        'title': 'Help John for Surgery',
        'purpose': 'Medical',
        'collected': 35000.0,
        'target': 50000.0,
      },
      {
        'title': 'Books for Orphanage',
        'purpose': 'Education',
        'collected': 12000.0,
        'target': 20000.0,
      },
      {
        'title': 'Startup Fund for Priya',
        'purpose': 'Personal',
        'collected': 8000.0,
        'target': 15000.0,
      },
    ];

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'FriendFund'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: GridView.count(
              crossAxisCount: isMobile ? 1 : 2,
              childAspectRatio: isMobile ? 1.2 : 2.5,
              children: campaigns
                  .map(
                    (c) => CampaignCard(
                      title: c['title'] as String,
                      purpose: c['purpose'] as String,
                      collected: c['collected'] as double,
                      target: c['target'] as double,
                      onTap: () =>
                          Navigator.pushNamed(context, '/campaign-details'),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () => Navigator.pushNamed(context, '/add-campaign'),
        tooltip: 'Add Campaign',
      ),
    );
  }
}
