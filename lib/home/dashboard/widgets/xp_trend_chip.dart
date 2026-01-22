import 'package:flutter/material.dart';

class XPTrendChip extends StatelessWidget {
  final String value;

  const XPTrendChip({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
