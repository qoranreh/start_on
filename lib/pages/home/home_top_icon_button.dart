import 'package:flutter/material.dart';

// 홈 상단 헤더에서 재사용하는 작은 액션 버튼입니다.
class HomeTopIconButton extends StatelessWidget {
  const HomeTopIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF111318), size: 22),
      ),
    );
  }
}
