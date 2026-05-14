import 'package:flutter/material.dart';

class ProfileStatBar extends StatelessWidget {
  const ProfileStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.score,
    required this.color,
  });

  final String label;
  final double value;
  final String score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              score,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF33415C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: const Color(0xFFE9EDF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
