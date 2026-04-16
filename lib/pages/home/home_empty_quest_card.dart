import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;

// 등록된 퀘스트가 없을 때 첫 추가 행동을 유도하는 빈 상태 카드입니다.
class HomeEmptyQuestCard extends StatelessWidget {
  const HomeEmptyQuestCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: neu.Neumorphic(
        style: neu.NeumorphicStyle(
          depth: 8,
          intensity: 0.8,
          surfaceIntensity: 0.28,
          color: const Color(0xFFF7FAFF),
          shadowLightColor: Colors.white,
          shadowDarkColor: const Color(0xFFD6DFEC),
          boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 34, color: Color(0xFFC0C7D4)),
            SizedBox(height: 12),
            Text(
              '등록된 퀘스트가 없습니다',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF33415C),
              ),
            ),
            SizedBox(height: 6),
            Text(
              '이 카드를 눌러 첫 퀘스트를 추가하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF8E9AAE)),
            ),
          ],
        ),
      ),
    );
  }
}
