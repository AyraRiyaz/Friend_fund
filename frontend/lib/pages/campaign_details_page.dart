import 'package:flutter/material.dart';

class CampaignDetailsPage extends StatelessWidget {
  const CampaignDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Campaign Details Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
