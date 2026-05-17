import 'package:start_on/models/quest_api_models.dart';
import 'package:start_on/models/quest_category.dart';
import 'package:start_on/models/quest_item.dart';

class CompletedQuestRecord {
  CompletedQuestRecord({
    required this.questId,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.earnedExp,
    required this.completedAt,
    required this.elapsedSeconds,
    List<QuestSubtask>? subtasks,
    this.proofImagePath,
  }) : subtasks = List.unmodifiable(subtasks ?? const <QuestSubtask>[]);

  final String questId;
  final String title;
  final String difficulty;
  final String category;
  final int earnedExp;
  final String completedAt;
  final int elapsedSeconds;
  final List<QuestSubtask> subtasks;
  final String? proofImagePath;

  factory CompletedQuestRecord.fromApiResponse(
    CompletedQuestRecordResponse response,
  ) {
    return CompletedQuestRecord(
      questId: response.questId,
      title: response.title,
      difficulty: questDifficultyFromApi(response.difficulty),
      category: normalizeQuestCategory(response.category),
      earnedExp: response.earnedExp,
      completedAt: response.completedAt,
      elapsedSeconds: response.elapsedSeconds,
      subtasks: const <QuestSubtask>[],
      proofImagePath: response.proofImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questId': questId,
      'title': title,
      'difficulty': difficulty,
      'category': category,
      'earnedExp': earnedExp,
      'completedAt': completedAt,
      'elapsedSeconds': elapsedSeconds,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'proofImagePath': proofImagePath,
    };
  }

  factory CompletedQuestRecord.fromJson(Map<String, dynamic> json) {
    return CompletedQuestRecord(
      questId: json['questId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      difficulty: normalizeQuestDifficulty(json['difficulty'] as String?),
      category: normalizeQuestCategory(json['category'] as String?),
      earnedExp: json['earnedExp'] as int? ?? 0,
      completedAt: json['completedAt'] as String? ?? '',
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      subtasks: _completedRecordSubtasksFromJson(json['subtasks']),
      proofImagePath: json['proofImagePath'] as String?,
    );
  }
}

List<QuestSubtask> _completedRecordSubtasksFromJson(Object? value) {
  if (value is! List) {
    return const <QuestSubtask>[];
  }

  return value
      .whereType<Map>()
      .map((item) => QuestSubtask.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
