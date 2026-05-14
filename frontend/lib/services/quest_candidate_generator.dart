import 'package:start_on/models/quest_item.dart';

class QuestCandidateGenerator {
  List<QuestItem> generateFromText(String text) {
    final lines = _extractCandidateLines(text);
    return lines.take(8).toList().asMap().entries.map((entry) {
      final title = entry.value;
      final difficulty = _estimateDifficulty(title);
      return QuestItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
        title: title,
        exp: _expForDifficulty(difficulty),
        difficulty: difficulty,
        category: _estimateCategory(title),
        elapsedSeconds: 0,
        defaultDurationSeconds: defaultQuestDurationSecondsForDifficulty(
          difficulty,
        ),
      );
    }).toList();
  }

  List<String> _extractCandidateLines(String text) {
    final seen = <String>{};
    final lines = <String>[];

    for (final rawLine in text.split('\n')) {
      final line = _sanitizeLine(rawLine);
      if (!_isQuestCandidate(line)) {
        continue;
      }

      final dedupeKey = line.toLowerCase();
      if (!seen.add(dedupeKey)) {
        continue;
      }

      lines.add(line);
    }

    return lines;
  }

  String _sanitizeLine(String line) {
    return line
        .replaceAll(
          RegExp(r'^\s*(?:[-*•·▪▫]|[0-9]+[.)]|☐|☑|✓|✔|\[[ xX]?\])\s*'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,;:]+$'), '')
        .trim();
  }

  bool _isQuestCandidate(String line) {
    if (line.length < 2 || line.length > 42) {
      return false;
    }

    if (RegExp(r'^[0-9\s:/.-]+$').hasMatch(line)) {
      return false;
    }

    if (RegExp(r'^[ㄱ-ㅎㅏ-ㅣa-zA-Z0-9 ]{1,2}$').hasMatch(line)) {
      return false;
    }

    return true;
  }

  String _estimateDifficulty(String title) {
    const easyKeywords = [
      '확인',
      '정리',
      '체크',
      '구매',
      '장보기',
      '준비',
      '예약',
      '메일',
      '답장',
    ];
    const hardKeywords = [
      '발표',
      '기획',
      '분석',
      '설계',
      '리포트',
      '보고서',
      '프로젝트',
      '정리본',
      '강의',
      '학습',
    ];

    if (hardKeywords.any(title.contains) || title.length >= 18) {
      return '어려움';
    }

    if (easyKeywords.any(title.contains) || title.length <= 7) {
      return '쉬움';
    }

    return '보통';
  }

  String _estimateCategory(String title) {
    final scores = <String, int>{'work': 0, 'life': 0, 'study': 0, 'home': 0};

    void addMatches(String category, List<String> keywords) {
      for (final keyword in keywords) {
        if (title.contains(keyword)) {
          scores.update(category, (value) => value + 1);
        }
      }
    }

    addMatches('life', ['운동', '스트레칭', '러닝', '헬스', '산책', '요가', '조깅', '필라테스']);
    addMatches('study', [
      '공부',
      '학습',
      '독서',
      '강의',
      '리서치',
      '분석',
      '설계',
      '연습',
      '정리본',
    ]);
    addMatches('home', [
      '청소',
      '세탁',
      '장보기',
      '구매',
      '준비',
      '정리',
      '예약',
      '확인',
      '체크',
      '챙기기',
    ]);
    addMatches('work', [
      '회의',
      '업무',
      '발표',
      '문서',
      '보고서',
      '기획',
      '검토',
      '이메일',
      '메일',
      '자료',
    ]);

    return scores.entries.reduce((best, current) {
      if (current.value > best.value) {
        return current;
      }
      return best;
    }).key;
  }

  int _expForDifficulty(String difficulty) {
    return switch (difficulty) {
      '쉬움' => 30,
      '보통' => 50,
      _ => 100,
    };
  }
}
