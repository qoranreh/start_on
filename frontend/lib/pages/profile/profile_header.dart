import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.onOpenRecord});

  final VoidCallback onOpenRecord;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '캐릭터',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2940),
            ),
          ),
        ),
        TextButton(onPressed: onOpenRecord, child: const Text('기록 보기')),
      ],
    );
  }
}
