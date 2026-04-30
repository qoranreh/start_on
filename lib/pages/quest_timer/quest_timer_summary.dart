import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:start_on/models/app_local_data.dart';

class QuestTimerSummary extends StatelessWidget {
  const QuestTimerSummary({
    super.key,
    required this.quest,
    required this.userLevel,
    required this.earnedExp,
    required this.maxDurationSeconds,
  });

  final QuestItem quest;
  final int userLevel;
  final int earnedExp;
  final int maxDurationSeconds;

  @override
  Widget build(BuildContext context) {
    final categoryStyle = questCategoryStyleFor(quest.category);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 320),
        child: neu.Neumorphic(
          style: neu.NeumorphicStyle(
            depth: 7,
            intensity: 0.9,
            surfaceIntensity: 0.24,
            color: const Color(0xFFF1F3F8),
            shadowLightColor: Colors.white,
            shadowDarkColor: const Color(0xFFD0D7E5),
            boxShape: neu.NeumorphicBoxShape.roundRect(
              BorderRadius.circular(14),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Row(
            children: [
              Icon(
                _questTitleIconFor(categoryStyle.category),
                size: 22,
                color: Colors.black,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quest.title,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2940),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lv.$userLevel',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$earnedExp EXP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7E899D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _questTitleIconFor(String category) {
  return switch (category) {
    'work' => Icons.laptop_mac_rounded,
    'life' => Icons.flag_rounded,
    'study' => Icons.school_rounded,
    'home' => Icons.home_rounded,
    _ => Icons.task_alt_rounded,
  };
}

// 퀘스트 난이도, 보상, 카테고리 같은 요약 정보를 공통 칩으로 표시한다.
class QuestTimerInfoChip extends StatelessWidget {
  const QuestTimerInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return neu.Neumorphic(
      style: neu.NeumorphicStyle(
        depth: 5,
        intensity: 0.88,
        surfaceIntensity: 0.18,
        color: backgroundColor,
        shadowLightColor: Colors.white.withValues(alpha: 0.98),
        shadowDarkColor: foregroundColor.withValues(alpha: 0.18),
        boxShape: const neu.NeumorphicBoxShape.stadium(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
