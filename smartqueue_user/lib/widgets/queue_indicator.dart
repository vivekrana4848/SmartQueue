import 'package:flutter/material.dart';

class QueueIndicator extends StatelessWidget {
  final int waitMinutes;

  const QueueIndicator({super.key, required this.waitMinutes});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (waitMinutes < 10) {
      color = const Color(0xFF22C55E); // Success Green
      label = 'Low Load';
      icon = Icons.bolt;
    } else if (waitMinutes < 30) {
      color = const Color(0xFFF59E0B); // Amber
      label = 'Moderate';
      icon = Icons.access_time;
    } else {
      color = const Color(0xFFEF4444); // Red
      label = 'High Load';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
