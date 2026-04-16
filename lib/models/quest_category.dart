import 'package:flutter/material.dart';

const List<String> questCategories = ['work', 'life', 'study', 'home'];

class QuestCategoryStyle {
  const QuestCategoryStyle({
    required this.category,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String category;
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
}

QuestCategoryStyle questCategoryStyleFor(String category) {
  return switch (normalizeQuestCategory(category)) {
    'work' => const QuestCategoryStyle(
      category: 'work',
      label: 'Work',
      icon: Icons.work_outline_rounded,
      accentColor: Color(0xFF5C7CFA),
      backgroundColor: Color(0xFFF2F5FF),
    ),
    'life' => const QuestCategoryStyle(
      category: 'life',
      label: 'Life',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xFFFF8A65),
      backgroundColor: Color(0xFFFFF1EB),
    ),
    'study' => const QuestCategoryStyle(
      category: 'study',
      label: 'Study',
      icon: Icons.psychology_alt_outlined,
      accentColor: Color(0xFF26A69A),
      backgroundColor: Color(0xFFECFAF8),
    ),
    'home' => const QuestCategoryStyle(
      category: 'home',
      label: 'Home',
      icon: Icons.checklist_rounded,
      accentColor: Color(0xFFFFC857),
      backgroundColor: Color(0xFFFFF8E7),
    ),
    _ => const QuestCategoryStyle(
      category: 'work',
      label: '업무',
      icon: Icons.work_outline_rounded,
      accentColor: Color(0xFF5C7CFA),
      backgroundColor: Color(0xFFF2F5FF),
    ),
  };
}

String questCategoryLabel(String category) =>
    questCategoryStyleFor(category).label;

String normalizeQuestCategory(String? category) {
  switch (category) {
    case 'work':
    case 'life':
    case 'study':
    case 'home':
      return category!;
    case 'exercise':
      return 'life';
    case 'A&I':
      return 'study';
    case 'todo':
      return 'home';
    case '정돈':
      return 'home';
    case '지능':
      return 'study';
    case '체력':
      return 'life';
    default:
      return 'work';
  }
}
