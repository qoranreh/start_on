import 'package:flutter/material.dart';
import 'package:start_on/widgets/common.dart';

class RecordSummaryCard extends StatelessWidget {
  const RecordSummaryCard({
    super.key,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NeumorphicRoundedCard(
      padding: const EdgeInsets.all(18),
      color: bgColor,
      borderRadius: 22,
      surfaceIntensity: 0.24,
      shadowDarkColor: bgColor.withValues(alpha: 0.46),
      shadowLightColor: Colors.white.withValues(alpha: 0.88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
