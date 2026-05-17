import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/task_intake_api_models.dart';
import 'package:start_on/pages/task_candidate_review_screen.dart';

void main() {
  testWidgets('renders candidate review details', (tester) async {
    await tester.pumpWidget(_ReviewHarness(candidate: _candidate()));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('AI 제안 확인'), findsOneWidget);
    expect(find.text('컴퓨터비전 과제 제출 준비'), findsOneWidget);
    expect(find.text('과제 파일을 열고 요구사항만 확인하기'), findsOneWidget);
    expect(find.text('오늘은 첫 단계만 진행해도 시작 장벽을 낮출 수 있음'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('오늘 계획이 이미 많아서 첫 단계만 추천해요.'),
      240,
    );
    expect(find.text('오늘 계획이 이미 많아서 첫 단계만 추천해요.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('과제 파일 열기'), 240);
    expect(find.text('과제 파일 열기'), findsOneWidget);
    expect(find.text('요구사항 체크리스트 만들기'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('딱 5분만 과제 파일 열기'), 240);
    expect(find.text('딱 5분만 과제 파일 열기'), findsOneWidget);
    expect(find.text('다음 행동'), findsWidgets);
  });

  testWidgets('renders deferred today recommendation and overload warning', (
    tester,
  ) async {
    await tester.pumpWidget(_ReviewHarness(candidate: _deferredCandidate()));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('오늘은 보류 추천'), findsOneWidget);
    expect(find.text('오늘 추천할 항목이 이미 충분해요.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('이 일은 Inbox에 두고 오늘은 이미 정한 항목만 처리해요.'),
      240,
    );
    expect(
      find.text('이 일은 Inbox에 두고 오늘은 이미 정한 항목만 처리해요.'),
      findsOneWidget,
    );
  });

  testWidgets('toggles selected subtasks and reminders before save', (
    tester,
  ) async {
    TaskCandidateReviewResult? result;

    await tester.pumpWidget(
      _ReviewHarness(
        candidate: _candidate(),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subtask-subtask-2')),
      240,
    );
    await tester.tap(find.text('요구사항 체크리스트 만들기'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reminder-reminder-1')),
      240,
    );
    await tester.tap(find.text('딱 5분만 과제 파일 열기'));
    await tester.tap(find.text('이대로 저장'));
    await tester.pumpAndSettle();

    expect(result?.action, TaskCandidateReviewAction.saveAsIs);
    expect(result?.candidateId, 'candidate-1');
    expect(result?.selectedSubtaskIds, ['subtask-1']);
    expect(result?.selectedReminderIds, isEmpty);
    expect(result?.editedFields, isEmpty);
  });

  testWidgets('does not submit reminders without remindAt', (tester) async {
    TaskCandidateReviewResult? result;

    await tester.pumpWidget(
      _ReviewHarness(
        candidate: _candidateWithUnscheduledReminder(),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reminder-reminder-unscheduled')),
      240,
    );
    expect(find.text('시간 없음'), findsOneWidget);

    await tester.tap(find.text('지금 딱 5분만 과제 파일 열기'));
    await tester.tap(find.text('이대로 저장'));
    await tester.pumpAndSettle();

    expect(result?.action, TaskCandidateReviewAction.saveAsIs);
    expect(result?.selectedReminderIds, isEmpty);
  });

  testWidgets('returns saveTodayOnly result', (tester) async {
    final result = await _tapAction(tester, '오늘 할 만큼만');

    expect(result?.action, TaskCandidateReviewAction.saveTodayOnly);
  });

  testWidgets('returns makeSmaller result', (tester) async {
    final result = await _tapAction(tester, '더 작게');

    expect(result?.action, TaskCandidateReviewAction.makeSmaller);
  });

  testWidgets('returns reduceReminders result', (tester) async {
    final result = await _tapAction(tester, '리마인더 줄이기');

    expect(result?.action, TaskCandidateReviewAction.reduceReminders);
  });

  testWidgets('returns cancel result', (tester) async {
    final result = await _tapAction(tester, '취소');

    expect(result?.action, TaskCandidateReviewAction.cancel);
  });

  testWidgets('renders empty states when candidate has no children', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReviewHarness(candidate: _candidateWithoutItems()),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('제안된 세부 단계가 없어요.'), 240);
    expect(find.text('제안된 세부 단계가 없어요.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('제안된 리마인더가 없어요.'), 240);
    expect(find.text('제안된 리마인더가 없어요.'), findsOneWidget);
  });
}

Future<TaskCandidateReviewResult?> _tapAction(
  WidgetTester tester,
  String label,
) async {
  TaskCandidateReviewResult? result;

  await tester.pumpWidget(
    _ReviewHarness(
      candidate: _candidate(),
      onResult: (value) => result = value,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(label));
  await tester.pumpAndSettle();

  return result;
}

class _ReviewHarness extends StatelessWidget {
  const _ReviewHarness({required this.candidate, this.onResult});

  final TaskCandidateResponse candidate;
  final ValueChanged<TaskCandidateReviewResult?>? onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<TaskCandidateReviewResult>(
                        MaterialPageRoute<TaskCandidateReviewResult>(
                          builder: (_) =>
                              TaskCandidateReviewScreen(candidate: candidate),
                        ),
                      );
                  onResult?.call(result);
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );
  }
}

TaskCandidateResponse _candidate() {
  return TaskCandidateResponse(
    id: 'candidate-1',
    userId: 'user-1',
    rawInputId: 'raw-1',
    mediatorRunId: 'run-1',
    title: '컴퓨터비전 과제 제출 준비',
    description: '요구사항 확인부터 시작',
    dueAt: DateTime.parse('2026-05-15T20:00:00+09:00'),
    priority: 'high',
    estimatedMinutes: 120,
    energyRequired: 'medium',
    difficulty: 'high',
    nextAction: '과제 파일을 열고 요구사항만 확인하기',
    recommendedToday: true,
    todayReason: '오늘은 첫 단계만 진행해도 시작 장벽을 낮출 수 있음',
    overloadWarning: '오늘 계획이 이미 많아서 첫 단계만 추천해요.',
    confidence: 0.82,
    status: 'draft',
    modelPayload: const <String, dynamic>{},
    subtasks: [
      CandidateSubtaskResponse(
        id: 'subtask-1',
        candidateId: 'candidate-1',
        title: '과제 파일 열기',
        orderIndex: 0,
        estimatedMinutes: 5,
        isNextAction: true,
        energyRequired: 'low',
        createdAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
        updatedAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
      ),
      CandidateSubtaskResponse(
        id: 'subtask-2',
        candidateId: 'candidate-1',
        title: '요구사항 체크리스트 만들기',
        orderIndex: 1,
        estimatedMinutes: 10,
        isNextAction: false,
        energyRequired: 'medium',
        createdAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
        updatedAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
      ),
    ],
    reminders: [
      CandidateReminderResponse(
        id: 'reminder-1',
        candidateId: 'candidate-1',
        remindAt: DateTime.parse('2026-05-14T20:00:00+09:00'),
        message: '딱 5분만 과제 파일 열기',
        type: 'start',
        escalationLevel: 0,
        createdAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
        updatedAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
      ),
    ],
    createdAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
    updatedAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
  );
}

TaskCandidateResponse _deferredCandidate() {
  final candidate = _candidate();
  return TaskCandidateResponse(
    id: candidate.id,
    userId: candidate.userId,
    rawInputId: candidate.rawInputId,
    mediatorRunId: candidate.mediatorRunId,
    title: candidate.title,
    description: candidate.description,
    dueAt: candidate.dueAt,
    priority: candidate.priority,
    estimatedMinutes: candidate.estimatedMinutes,
    energyRequired: candidate.energyRequired,
    difficulty: candidate.difficulty,
    nextAction: candidate.nextAction,
    recommendedToday: false,
    todayReason: '오늘 추천할 항목이 이미 충분해요.',
    overloadWarning: '이 일은 Inbox에 두고 오늘은 이미 정한 항목만 처리해요.',
    confidence: candidate.confidence,
    status: candidate.status,
    modelPayload: candidate.modelPayload,
    subtasks: candidate.subtasks,
    reminders: candidate.reminders,
    createdAt: candidate.createdAt,
    updatedAt: candidate.updatedAt,
  );
}

TaskCandidateResponse _candidateWithoutItems() {
  final candidate = _candidate();
  return TaskCandidateResponse(
    id: candidate.id,
    userId: candidate.userId,
    rawInputId: candidate.rawInputId,
    mediatorRunId: candidate.mediatorRunId,
    title: candidate.title,
    description: candidate.description,
    dueAt: candidate.dueAt,
    priority: candidate.priority,
    estimatedMinutes: candidate.estimatedMinutes,
    energyRequired: candidate.energyRequired,
    difficulty: candidate.difficulty,
    nextAction: candidate.nextAction,
    recommendedToday: false,
    todayReason: null,
    overloadWarning: null,
    confidence: candidate.confidence,
    status: candidate.status,
    modelPayload: candidate.modelPayload,
    subtasks: const <CandidateSubtaskResponse>[],
    reminders: const <CandidateReminderResponse>[],
    createdAt: candidate.createdAt,
    updatedAt: candidate.updatedAt,
  );
}

TaskCandidateResponse _candidateWithUnscheduledReminder() {
  final candidate = _candidate();
  return TaskCandidateResponse(
    id: candidate.id,
    userId: candidate.userId,
    rawInputId: candidate.rawInputId,
    mediatorRunId: candidate.mediatorRunId,
    title: candidate.title,
    description: candidate.description,
    dueAt: candidate.dueAt,
    priority: candidate.priority,
    estimatedMinutes: candidate.estimatedMinutes,
    energyRequired: candidate.energyRequired,
    difficulty: candidate.difficulty,
    nextAction: candidate.nextAction,
    recommendedToday: candidate.recommendedToday,
    todayReason: candidate.todayReason,
    overloadWarning: candidate.overloadWarning,
    confidence: candidate.confidence,
    status: candidate.status,
    modelPayload: candidate.modelPayload,
    subtasks: candidate.subtasks,
    reminders: [
      CandidateReminderResponse(
        id: 'reminder-unscheduled',
        candidateId: candidate.id,
        remindAt: null,
        message: '지금 딱 5분만 과제 파일 열기',
        type: 'start',
        escalationLevel: 0,
        createdAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
        updatedAt: DateTime.parse('2026-05-14T12:00:00+09:00'),
      ),
    ],
    createdAt: candidate.createdAt,
    updatedAt: candidate.updatedAt,
  );
}
