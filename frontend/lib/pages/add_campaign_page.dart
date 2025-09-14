import 'package:flutter/material.dart';

class AddCampaignPage extends StatelessWidget {
  const AddCampaignPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Add Campaign Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
