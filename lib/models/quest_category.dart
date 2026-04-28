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
      icon: Icons.work_rounded,
      accentColor: Color(0xFF63ADA8),
      backgroundColor: Color(0xFF68B3AD),
    ),
    'life' => const QuestCategoryStyle(
      category: 'life',
      label: 'Life',
      icon: Icons.flag_rounded,
      accentColor: Color(0xFFA7BFA8),
      backgroundColor: Color(0xFFA8BFAA),
    ),
    'study' => const QuestCategoryStyle(
      category: 'study',
      label: 'School',
      icon: Icons.school_rounded,
      accentColor: Color(0xFFF4CE46),
      backgroundColor: Color(0xFFFFD954),
    ),
    'home' => const QuestCategoryStyle(
      category: 'home',
      label: 'Home',
      icon: Icons.home_rounded,
      accentColor: Color(0xFFF39482),
      backgroundColor: Color(0xFFF79685),
    ),
    _ => const QuestCategoryStyle(
      category: 'work',
      label: '업무',
      icon: Icons.work_rounded,
      accentColor: Color(0xFF63ADA8),
      backgroundColor: Color(0xFF68B3AD),
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
