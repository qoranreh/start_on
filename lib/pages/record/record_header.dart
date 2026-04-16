import 'package:flutter/material.dart';

class RecordHeader extends StatelessWidget {
  const RecordHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 4),
        const Text(
          '기록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2940),
          ),
        ),
      ],
    );
  }
}
