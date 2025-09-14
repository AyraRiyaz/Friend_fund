import 'package:flutter/material.dart';

class MyCampaignsPage extends StatelessWidget {
  const MyCampaignsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'My Campaigns Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
