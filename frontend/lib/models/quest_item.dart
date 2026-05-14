import 'package:start_on/models/quest_category.dart';
import 'package:start_on/models/quest_api_models.dart';

const _questItemNoChange = Object();

class QuestItem {
  QuestItem({
    required this.id,
    required this.title,
    required this.exp,
    required this.difficulty,
    required this.category,
    required this.elapsedSeconds,
    required this.defaultDurationSeconds,
    this.dueDate,
  });

  final String id;
  final String title;
  final int exp;
  final String difficulty;
  final String category;
  final int elapsedSeconds;
  final int defaultDurationSeconds;
  final DateTime? dueDate;

  QuestItem copyWith({
    String? id,
    String? title,
    int? exp,
    String? difficulty,
    String? category,
    int? elapsedSeconds,
    int? defaultDurationSeconds,
    Object? dueDate = _questItemNoChange,
  }) {
    return QuestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      exp: exp ?? this.exp,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      defaultDurationSeconds:
          defaultDurationSeconds ?? this.defaultDurationSeconds,
      dueDate: identical(dueDate, _questItemNoChange)
          ? this.dueDate
          : dueDate as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'exp': exp,
      'difficulty': difficulty,
      'category': category,
      'elapsedSeconds': elapsedSeconds,
      'defaultDurationSeconds': defaultDurationSeconds,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory QuestItem.fromJson(Map<String, dynamic> json) {
    final difficulty = normalizeQuestDifficulty(json['difficulty'] as String?);
    final rawDueDate = json['dueDate'] as String?;
    return QuestItem(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      difficulty: difficulty,
      category: normalizeQuestCategory(json['category'] as String?),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      defaultDurationSeconds:
          json['defaultDurationSeconds'] as int? ??
          defaultQuestDurationSecondsForDifficulty(difficulty),
      dueDate: rawDueDate == null
          ? null
          : normalizeQuestDueDate(DateTime.tryParse(rawDueDate)),
    );
  }

  factory QuestItem.fromApiResponse(QuestItemResponse response) {
    return QuestItem(
      id: response.id,
      title: response.title,
      exp: response.exp,
      difficulty: questDifficultyFromApi(response.difficulty),
      category: normalizeQuestCategory(response.category),
      elapsedSeconds: response.elapsedSeconds,
      defaultDurationSeconds: response.defaultDurationSeconds,
    );
  }

  QuestCreateRequest toCreateRequest() {
    return QuestCreateRequest(
      title: title,
      exp: exp,
      difficulty: questDifficultyToApi(difficulty),
      category: normalizeQuestCategory(category),
      defaultDurationSeconds: defaultDurationSeconds,
    );
  }

  QuestUpdateRequest toUpdateRequest() {
    return QuestUpdateRequest(
      title: title,
      exp: exp,
      difficulty: questDifficultyToApi(difficulty),
      category: normalizeQuestCategory(category),
      elapsedSeconds: elapsedSeconds,
      defaultDurationSeconds: defaultDurationSeconds,
    );
  }
}

int defaultQuestDurationSecondsForDifficulty(String difficulty) {
  return switch (normalizeQuestDifficulty(difficulty)) {
    '쉬움' => 25 * 60,
    '보통' => 45 * 60,
    _ => 90 * 60,
  };
}

String normalizeQuestDifficulty(String? difficulty) {
  return switch (difficulty) {
    '쉬움' || 'easy' => '쉬움',
    '보통' || 'normal' => '보통',
    '어려움' || 'hard' => '어려움',
    _ => '보통',
  };
}

String questDifficultyFromApi(String difficulty) {
  return normalizeQuestDifficulty(difficulty);
}

String questDifficultyToApi(String difficulty) {
  return switch (normalizeQuestDifficulty(difficulty)) {
    '쉬움' => 'easy',
    '보통' => 'normal',
    '어려움' => 'hard',
    _ => 'normal',
  };
}

DateTime? normalizeQuestDueDate(DateTime? value) {
  if (value == null) {
    return null;
  }

  return DateTime(value.year, value.month, value.day);
}

String formatQuestDueDate(DateTime dueDate) {
  final normalized = normalizeQuestDueDate(dueDate)!;
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}
