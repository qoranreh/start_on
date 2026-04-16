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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF6D788A), size: 20),
      ),
    );
  }
}
