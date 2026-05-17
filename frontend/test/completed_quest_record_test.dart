import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/completed_quest_record.dart';
import 'package:start_on/models/quest_item.dart';

void main() {
  test('json preserves completed subtask timing snapshot', () {
    final record = CompletedQuestRecord(
      questId: 'task-1',
      title: 'AI 태스크',
      difficulty: '보통',
      category: 'study',
      earnedExp: 15,
      completedAt: '2026-05-16T12:00:00.000',
      elapsedSeconds: 900,
      subtasks: [
        QuestSubtask(
          id: 'subtask-1',
          title: '자료 열기',
          orderIndex: 0,
          estimatedMinutes: 5,
          status: 'done',
          completedAt: DateTime(2026, 5, 16, 11, 5),
          elapsedSeconds: 300,
        ),
      ],
    );

    final decoded = CompletedQuestRecord.fromJson(record.toJson());

    expect(decoded.subtasks, hasLength(1));
    expect(decoded.subtasks.single.id, 'subtask-1');
    expect(decoded.subtasks.single.status, 'done');
    expect(decoded.subtasks.single.elapsedSeconds, 300);
    expect(decoded.subtasks.single.completedAt, DateTime(2026, 5, 16, 11, 5));
  });
}
