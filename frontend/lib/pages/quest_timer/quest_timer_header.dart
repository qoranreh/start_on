import 'package:flutter/material.dart';

class QuestTimerHeader extends StatelessWidget {
  const QuestTimerHeader({
    super.key,
    required this.onBack,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Timer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C2940),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 21),
                color: const Color(0xFF1C2940),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
