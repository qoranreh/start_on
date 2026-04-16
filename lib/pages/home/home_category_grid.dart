import 'package:flutter/material.dart';
import 'package:start_on/models/quest_category.dart';
import 'package:start_on/pages/home/home_category_card.dart';

// 추천 카테고리를 2x2 그리드로 보여주는 정적 섹션입니다.
class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({
    super.key,
    required this.completedCategoryCounts,
    required this.pendingCategoryCounts,
    required this.onCategoryTap,
    required this.onAddCategoryQuest,
  });

  final Map<String, int> completedCategoryCounts;
  final Map<String, int> pendingCategoryCounts;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<String> onAddCategoryQuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryCard('work')),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard('life')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCategoryCard('study')),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard('home')),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    final style = questCategoryStyleFor(category);
    return HomeCategoryCard(
      title: style.label,
      completedCount: completedCategoryCounts[category] ?? 0,
      pendingCount: pendingCategoryCounts[category] ?? 0,
      onTap: () => onCategoryTap(category),
      onAddTap: () => onAddCategoryQuest(category),
      icon: style.icon,
      accentColor: style.accentColor,
      backgroundColor: style.backgroundColor,
    );
  }
}
