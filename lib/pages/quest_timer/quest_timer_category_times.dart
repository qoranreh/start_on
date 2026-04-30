import 'package:flutter/material.dart';
import 'package:start_on/models/quest_category.dart';

class QuestTimerCategoryTimes extends StatelessWidget {
  const QuestTimerCategoryTimes({
    super.key,
    required this.category,
    required this.elapsedSeconds,
    required this.formatDuration,
  });

  final String category;
  final int elapsedSeconds;
  final String Function(Duration duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = normalizeQuestCategory(category);
    final items = [
      _CategoryTimeItem(
        category: 'life',
        label: 'LIFE',
        icon: Icons.flag_rounded,
        color: const Color(0xFFA8BFAA),
      ),
      _CategoryTimeItem(
        category: 'work',
        label: 'WORK',
        icon: Icons.work_rounded,
        color: const Color(0xFF68B3AD),
      ),
      _CategoryTimeItem(
        category: 'study',
        label: 'SCHOOL',
        icon: Icons.school_rounded,
        color: const Color(0xFFFFD954),
      ),
      _CategoryTimeItem(
        category: 'home',
        label: 'HOME',
        icon: Icons.home_rounded,
        color: const Color(0xFFF79685),
      ),
    ];

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _CategoryTimeBar(
            item: items[index],
            timeLabel: items[index].category == normalizedCategory
                ? formatDuration(Duration(seconds: elapsedSeconds))
                : '00:00:00',
          ),
          if (index != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CategoryTimeBar extends StatelessWidget {
  const _CategoryTimeBar({required this.item, required this.timeLabel});

  final _CategoryTimeItem item;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.34),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: Colors.black),
          const SizedBox(width: 18),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8C919A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTimeItem {
  const _CategoryTimeItem({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String category;
  final String label;
  final IconData icon;
  final Color color;
}
