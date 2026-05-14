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
      color: const Color(0xFFF1F3F8),
      borderRadius: 22,
      depth: 6,
      intensity: 0.9,
      surfaceIntensity: 0.32,
      shadowDarkColor: const Color(0xFFD0D7E5),
      shadowLightColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7E899D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: bgColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF33415C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
