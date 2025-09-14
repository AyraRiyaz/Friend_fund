import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  const ProgressBar({Key? key, required this.value, this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).primaryColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: progressColor.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
      ),
    );
  }
}
