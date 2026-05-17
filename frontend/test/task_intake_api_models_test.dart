import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/task_intake_api_models.dart';

void main() {
  test('TaskIntakeRequest serializes backend snake case body', () {
    final request = TaskIntakeRequest(
      text: '  내일 컴비전 과제 해야 함  ',
      userContext: const TaskIntakeUserContext(
        energyNow: 'medium',
        availableMinutesToday: 60,
        extra: {'focus_mode': 'short'},
      ),
      clientMetadata: const {'entry_point': 'manual_input'},
    );

    expect(request.toJson(), {
      'text': '내일 컴비전 과제 해야 함',
      'source': 'manual',
      'client_timezone': 'Asia/Seoul',
      'user_context': {
        'energy_now': 'medium',
        'available_minutes_today': 60,
        'extra': {'focus_mode': 'short'},
      },
      'client_metadata': {'entry_point': 'manual_input'},
    });
  });

  test('candidate action requests serialize backend snake case bodies', () {
    const confirmRequest = TaskConfirmRequest(
      editedFields: {'title': '작게 시작하기'},
      selectedSubtaskIds: ['subtask-1'],
      selectedReminderIds: ['reminder-1'],
    );
    const reviseRequest = TaskCandidateReviseRequest(
      revisionType: 'make_smaller',
      editedFields: {'estimated_minutes': 15},
      note: '오늘 할 만큼만',
    );
    const rejectRequest = TaskCandidateRejectRequest(
      reason: 'cancelled_from_review',
    );

    expect(confirmRequest.toJson(), {
      'accepted': true,
      'edited_fields': {'title': '작게 시작하기'},
      'selected_subtask_ids': ['subtask-1'],
      'selected_reminder_ids': ['reminder-1'],
    });
    expect(reviseRequest.toJson(), {
      'revision_type': 'make_smaller',
      'edited_fields': {'estimated_minutes': 15},
      'note': '오늘 할 만큼만',
    });
    expect(rejectRequest.toJson(), {'reason': 'cancelled_from_review'});
  });

  test('TaskIntakeResponse parses candidate payload', () {
    final response = TaskIntakeResponse.fromJson(_intakePayload());

    expect(response.rawInputId, 'raw-1');
    expect(response.candidateId, 'candidate-1');
    expect(response.status, 'candidate_ready');
    expect(response.candidate?.title, '컴퓨터비전 과제 제출 준비');
    expect(
      response.candidate?.dueAt,
      DateTime.parse('2026-05-15T20:00:00+09:00'),
    );
    expect(response.candidate?.recommendedToday, isTrue);
    expect(response.candidate?.confidence, 0.82);
    expect(response.candidate?.modelPayload['planner'], 'mediator_v1');
    expect(response.candidate?.subtasks.single.isNextAction, isTrue);
    expect(response.candidate?.subtasks.single.orderIndex, 0);
    expect(response.candidate?.reminders.single.type, 'start');
    expect(
      response.candidate?.reminders.single.remindAt,
      DateTime.parse('2026-05-14T20:00:00+09:00'),
    );
  });

  test('TaskCommitResultResponse parses final task payload', () {
    final response = TaskCommitResultResponse.fromJson(_commitPayload());

    expect(response.candidateId, 'candidate-1');
    expect(response.task.id, 'task-1');
    expect(response.task.title, '컴퓨터비전 과제 제출 준비');
    expect(response.task.difficulty, 'high');
    expect(response.task.metadata['committed_from'], 'task_candidate');
    expect(response.task.subtasks.single.candidateSubtaskId, 'subtask-1');
    expect(response.task.subtasks.single.isNextAction, isTrue);
    expect(response.task.reminders.single.candidateReminderId, 'reminder-1');
    expect(response.task.reminders.single.status, 'scheduled');
  });

  test(
    'TaskIntakeResponse allows missing candidate when processing failed',
    () {
      final response = TaskIntakeResponse.fromJson({
        'raw_input_id': 'raw-1',
        'candidate_id': null,
        'status': 'failed',
        'candidate': null,
      });

      expect(response.candidateId, isNull);
      expect(response.candidate, isNull);
    },
  );

  test('TaskCandidateResponse rejects invalid subtask list', () {
    final payload = Map<String, dynamic>.from(_candidatePayload())
      ..['subtasks'] = 'invalid';

    expect(
      () => TaskCandidateResponse.fromJson(payload),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _intakePayload() {
  return {
    'raw_input_id': 'raw-1',
    'candidate_id': 'candidate-1',
    'status': 'candidate_ready',
    'candidate': _candidatePayload(),
  };
}

Map<String, dynamic> _candidatePayload() {
  return {
    'id': 'candidate-1',
    'user_id': 'user-1',
    'raw_input_id': 'raw-1',
    'mediator_run_id': 'run-1',
    'title': '컴퓨터비전 과제 제출 준비',
    'description': '과제 요구사항 확인부터 시작',
    'due_at': '2026-05-15T20:00:00+09:00',
    'priority': 'high',
    'estimated_minutes': 120,
    'energy_required': 'medium',
    'difficulty': 'high',
    'next_action': '과제 파일을 열고 요구사항만 확인하기',
    'recommended_today': true,
    'today_reason': '오늘은 첫 단계만 진행해도 시작 장벽을 낮출 수 있음',
    'overload_warning': null,
    'confidence': 0.82,
    'status': 'draft',
    'model_payload': {'planner': 'mediator_v1'},
    'subtasks': [
      {
        'id': 'subtask-1',
        'candidate_id': 'candidate-1',
        'title': '과제 파일 열기',
        'order_index': 0,
        'estimated_minutes': 5,
        'is_next_action': true,
        'energy_required': 'low',
        'created_at': '2026-05-14T12:00:00+09:00',
        'updated_at': '2026-05-14T12:00:00+09:00',
      },
    ],
    'reminders': [
      {
        'id': 'reminder-1',
        'candidate_id': 'candidate-1',
        'remind_at': '2026-05-14T20:00:00+09:00',
        'message': '딱 5분만 과제 파일 열기',
        'type': 'start',
        'escalation_level': 0,
        'created_at': '2026-05-14T12:00:00+09:00',
        'updated_at': '2026-05-14T12:00:00+09:00',
      },
    ],
    'created_at': '2026-05-14T12:00:00+09:00',
    'updated_at': '2026-05-14T12:00:00+09:00',
  };
}

Map<String, dynamic> _commitPayload() {
  return {
    'candidate_id': 'candidate-1',
    'task': {
      'id': 'task-1',
      'user_id': 'user-1',
      'candidate_id': 'candidate-1',
      'raw_input_id': 'raw-1',
      'mediator_run_id': 'run-1',
      'title': '컴퓨터비전 과제 제출 준비',
      'description': '과제 요구사항 확인부터 시작',
      'status': 'todo',
      'priority': 'high',
      'due_at': '2026-05-15T20:00:00+09:00',
      'estimated_minutes': 120,
      'energy_required': 'medium',
      'difficulty': 'high',
      'next_action': '과제 파일을 열고 요구사항만 확인하기',
      'source': 'ai',
      'metadata': {
        'committed_from': 'task_candidate',
        'selected_subtask_ids': ['subtask-1'],
      },
      'subtasks': [
        {
          'id': 'task-subtask-1',
          'task_id': 'task-1',
          'user_id': 'user-1',
          'candidate_subtask_id': 'subtask-1',
          'title': '과제 파일 열기',
          'order_index': 0,
          'estimated_minutes': 5,
          'status': 'todo',
          'is_next_action': true,
          'energy_required': 'low',
          'created_at': '2026-05-14T12:00:00+09:00',
          'updated_at': '2026-05-14T12:00:00+09:00',
          'completed_at': null,
        },
      ],
      'reminders': [
        {
          'id': 'task-reminder-1',
          'user_id': 'user-1',
          'task_id': 'task-1',
          'candidate_reminder_id': 'reminder-1',
          'remind_at': '2026-05-14T20:00:00+09:00',
          'message': '딱 5분만 과제 파일 열기',
          'type': 'start',
          'status': 'scheduled',
          'escalation_level': 0,
          'created_at': '2026-05-14T12:00:00+09:00',
          'updated_at': '2026-05-14T12:00:00+09:00',
          'sent_at': null,
        },
      ],
      'created_at': '2026-05-14T12:00:00+09:00',
      'updated_at': '2026-05-14T12:00:00+09:00',
      'completed_at': null,
    },
  };
}
