import 'package:flutter/material.dart';

class PublicCampaignPage extends StatelessWidget {
  const PublicCampaignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Public Campaign Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
