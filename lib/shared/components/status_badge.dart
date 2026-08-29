import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase().trim();
    Color bgColor;
    Color fgColor;
    IconData icon;

    switch (normalized) {
      case 'CONFIRMED':
      case 'ACTIVE':
      case 'PAID':
      case 'COMPLETED':
      case 'APPROVED':
        bgColor = Colors.green.withValues(alpha: 0.15);
        fgColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case 'PENDING':
      case 'UPCOMING':
      case 'IN_PROGRESS':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        fgColor = Colors.orange.shade900;
        icon = Icons.schedule;
        break;
      case 'CANCELLED':
      case 'FAILED':
      case 'REJECTED':
      case 'INACTIVE':
        bgColor = Colors.red.withValues(alpha: 0.15);
        fgColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        fgColor = Colors.grey.shade800;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fgColor),
          const SizedBox(width: 4),
          Text(
            normalized,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
