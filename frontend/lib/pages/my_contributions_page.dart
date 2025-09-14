import 'package:flutter/material.dart';

class MyContributionsPage extends StatelessWidget {
  const MyContributionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'My Contributions Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
