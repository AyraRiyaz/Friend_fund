import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  const ProgressBar({Key? key, required this.value, this.color = Colors.teal})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
