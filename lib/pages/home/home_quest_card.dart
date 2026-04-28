import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:start_on/models/app_local_data.dart';

// 진행 중인 퀘스트 하나를 요약해서 보여주는 카드입니다.
class HomeQuestCard extends StatelessWidget {
  const HomeQuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    required this.onDelete,
  });

  final QuestItem quest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _categoryStyleFor(quest.category);
    final elapsedLabel = _formatElapsedSeconds(quest.elapsedSeconds);
    final dueDate = quest.dueDate;

    return GestureDetector(
      onTap: onTap,
      child: neu.Neumorphic(
        style: neu.NeumorphicStyle(
          depth: 8,
          intensity: 0.8,
          surfaceIntensity: 0.28,
          color: const Color(0xFFF7FAFF),
          shadowLightColor: Colors.white.withValues(alpha: 0.94),
          shadowDarkColor: const Color(0xFFD6DFEC),
          boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            // 아직 완료되지 않은 상태를 표현하는 체크 슬롯입니다.
            neu.Neumorphic(
              style: neu.NeumorphicStyle(
                depth: 2,
                intensity: 0.82,
                surfaceIntensity: 0.18,
                color: const Color(0xFFF7FAFF),
                shadowLightColor: Colors.white,
                shadowDarkColor: const Color(0xFFD8E0EB),
                boxShape: neu.NeumorphicBoxShape.roundRect(
                  BorderRadius.circular(10),
                ),
              ),
              child: const SizedBox(width: 28, height: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              // 퀘스트 제목과 난이도/카테고리 메타 정보를 표시합니다.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33415C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        quest.difficulty,
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _HomeQuestMetaChip(
                        icon: Icons.schedule_rounded,
                        label: elapsedLabel,
                        color: Color(0xFF98A2B3),
                        backgroundColor: Color(0xFFF1F4F9),
                      ),
                      if (dueDate != null)
                        _HomeQuestMetaChip(
                          icon: Icons.event_outlined,
                          label: formatQuestDueDate(dueDate),
                          color: categoryStyle.accentColor,
                          backgroundColor: categoryStyle.backgroundColor,
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryStyle.backgroundColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          quest.category,
                          style: TextStyle(
                            color: categoryStyle.accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 우측 휴지통 버튼으로 퀘스트를 바로 삭제합니다.
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFC0C7D4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatElapsedSeconds(int elapsedSeconds) {
  final hours = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

_HomeQuestCategoryStyle _categoryStyleFor(String category) {
  final style = questCategoryStyleFor(category);
  return _HomeQuestCategoryStyle(
    accentColor: style.accentColor,
    backgroundColor: style.backgroundColor,
  );
}

class _HomeQuestCategoryStyle {
  const _HomeQuestCategoryStyle({
    required this.accentColor,
    required this.backgroundColor,
  });

  final Color accentColor;
  final Color backgroundColor;
}

class _HomeQuestMetaChip extends StatelessWidget {
  const _HomeQuestMetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return neu.Neumorphic(
      style: neu.NeumorphicStyle(
        depth: 3,
        intensity: 0.68,
        surfaceIntensity: 0.18,
        color: backgroundColor,
        shadowLightColor: Colors.white.withValues(alpha: 0.9),
        shadowDarkColor: const Color(0xFFD8E0EB),
        boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(999)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
