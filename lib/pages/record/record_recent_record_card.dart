import 'package:flutter/material.dart';
import 'package:start_on/widgets/common.dart';

class RecordRecentRecordCard extends StatelessWidget {
  const RecordRecentRecordCard({
    super.key,
    required this.date,
    required this.subtitle,
    required this.exp,
  });

  final String date;
  final String subtitle;
  final String exp;

  @override
  Widget build(BuildContext context) {
    return NeumorphicRoundedCard(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFFF8FBFF),
      shadowDarkColor: const Color(0xFFD5DDEA),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF7E899D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                exp,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF8B93),
                ),
              ),
              const Text(
                'EXP',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }
}
