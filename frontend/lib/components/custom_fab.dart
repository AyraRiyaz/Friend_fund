import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  const CustomFAB({Key? key, required this.onPressed, this.tooltip})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip ?? 'Add',
      child: const Icon(Icons.add, size: 32),
      shape: const StadiumBorder(),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 6,
    );
  }
}
