import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/completed_quest_record.dart';
import 'package:start_on/models/quest_item.dart';
import 'package:start_on/pages/quest_timer_screen.dart';

void main() {
  testWidgets(
    'subtask timer advances to next subtask and completes parent quest',
    (tester) async {
      final changedQuests = <QuestItem>[];
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push<Object?>(
                        MaterialPageRoute<Object?>(
                          builder: (_) => QuestTimerScreen(
                            quest: _timedSubtaskQuest(),
                            userLevel: 1,
                            notificationsEnabled: false,
                            onQuestChanged: changedQuests.add,
                          ),
                        ),
                      )
                      .then((value) => result = value);
                },
                child: const Text('open timer'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open timer'));
      await tester.pumpAndSettle();

      expect(find.text('진행 중 · 0:00/1:00'), findsOneWidget);
      expect(find.text('대기 · 0:00/1:00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded).last);
      await tester.pump();

      for (var i = 0; i < 60; i += 1) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('완료됨 · 1:00/1:00'), findsOneWidget);
      expect(find.text('진행 중 · 0:00/1:00'), findsOneWidget);
      expect(changedQuests.last.activeSubtaskId, 'subtask-2');
      expect(changedQuests.last.subtasks.first.status, 'done');
      expect(changedQuests.last.subtasks.first.elapsedSeconds, 60);

      for (var i = 0; i < 60; i += 1) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();

      expect(result, isA<CompletedQuestRecord>());
      final record = result! as CompletedQuestRecord;
      expect(record.questId, 'quest-1');
      expect(record.elapsedSeconds, 120);
      expect(record.subtasks, hasLength(2));
      expect(record.subtasks.map((subtask) => subtask.status), [
        'done',
        'done',
      ]);
      expect(record.subtasks.map((subtask) => subtask.elapsedSeconds), [
        60,
        60,
      ]);
    },
  );
}

QuestItem _timedSubtaskQuest() {
  return QuestItem(
    id: 'quest-1',
    title: '순차 작업',
    exp: 30,
    difficulty: '쉬움',
    category: 'study',
    elapsedSeconds: 0,
    defaultDurationSeconds: 25 * 60,
    activeSubtaskId: 'subtask-1',
    subtasks: const [
      QuestSubtask(
        id: 'subtask-1',
        title: '첫 번째 단계',
        orderIndex: 0,
        estimatedMinutes: 1,
      ),
      QuestSubtask(
        id: 'subtask-2',
        title: '두 번째 단계',
        orderIndex: 1,
        estimatedMinutes: 1,
      ),
    ],
  );
}
