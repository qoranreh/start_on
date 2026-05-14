import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/quest_api_models.dart';
import 'package:start_on/models/quest_item.dart';

void main() {
  test('fromApiResponse maps server quest fields to screen model fields', () {
    const response = QuestItemResponse(
      id: 'quest-1',
      title: '서버 퀘스트',
      exp: 50,
      difficulty: 'normal',
      category: 'study',
      elapsedSeconds: 120,
      defaultDurationSeconds: 2700,
    );

    final quest = QuestItem.fromApiResponse(response);

    expect(quest.id, 'quest-1');
    expect(quest.title, '서버 퀘스트');
    expect(quest.exp, 50);
    expect(quest.difficulty, '보통');
    expect(quest.category, 'study');
    expect(quest.elapsedSeconds, 120);
    expect(quest.defaultDurationSeconds, 2700);
    expect(quest.dueDate, isNull);
  });

  test('toCreateRequest maps screen model fields to server request fields', () {
    final quest = QuestItem(
      id: 'local-1',
      title: ' 새 퀘스트 ',
      exp: 100,
      difficulty: '어려움',
      category: 'A&I',
      elapsedSeconds: 300,
      defaultDurationSeconds: 5400,
      dueDate: DateTime(2026, 5, 9),
    );

    final request = quest.toCreateRequest();

    expect(request.toJson(), {
      'title': '새 퀘스트',
      'exp': 100,
      'difficulty': 'hard',
      'category': 'study',
      'defaultDurationSeconds': 5400,
    });
  });

  test('toUpdateRequest includes elapsed seconds for server updates', () {
    final quest = QuestItem(
      id: 'quest-1',
      title: '진행 중 퀘스트',
      exp: 30,
      difficulty: '쉬움',
      category: 'life',
      elapsedSeconds: 600,
      defaultDurationSeconds: 1500,
    );

    final request = quest.toUpdateRequest();

    expect(request.toJson(), {
      'title': '진행 중 퀘스트',
      'exp': 30,
      'difficulty': 'easy',
      'category': 'life',
      'elapsedSeconds': 600,
      'defaultDurationSeconds': 1500,
    });
  });

  test('fromJson accepts server difficulty names from cached data', () {
    final quest = QuestItem.fromJson({
      'id': 'quest-1',
      'title': '캐시 퀘스트',
      'exp': 50,
      'difficulty': 'normal',
      'category': 'work',
      'elapsedSeconds': 0,
    });

    expect(quest.difficulty, '보통');
    expect(quest.defaultDurationSeconds, 45 * 60);
  });
}
