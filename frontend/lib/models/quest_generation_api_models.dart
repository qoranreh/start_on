class QuestCandidateResponse {
  const QuestCandidateResponse({
    required this.title,
    required this.difficulty,
    required this.category,
    required this.exp,
    required this.defaultDurationSeconds,
    required this.reason,
  });

  factory QuestCandidateResponse.fromJson(Object? json) {
    final object = _asJsonObject(
      json,
      'Quest candidate must be a JSON object.',
    );
    return QuestCandidateResponse(
      title: _readRequiredString(object, 'title'),
      difficulty: _readRequiredString(object, 'difficulty'),
      category: _readRequiredString(object, 'category'),
      exp: _readInt(object, 'exp'),
      defaultDurationSeconds: _readInt(object, 'defaultDurationSeconds'),
      reason: _readOptionalString(object, 'reason'),
    );
  }

  final String title;
  final String difficulty;
  final String category;
  final int exp;
  final int defaultDurationSeconds;
  final String? reason;
}

class OCRTextQuestExtractionResponse {
  const OCRTextQuestExtractionResponse({
    required this.quests,
    required this.cleanedLines,
    required this.duplicateRemovedCount,
  });

  factory OCRTextQuestExtractionResponse.fromJson(Object? json) {
    final object = _asJsonObject(
      json,
      'OCR text extraction result must be a JSON object.',
    );
    final rawQuests = object['quests'] as List<dynamic>? ?? const [];
    final rawCleanedLines =
        object['cleaned_lines'] as List<dynamic>? ?? const [];
    return OCRTextQuestExtractionResponse(
      quests: rawQuests.map(QuestCandidateResponse.fromJson).toList(),
      cleanedLines: rawCleanedLines.map((item) => item.toString()).toList(),
      duplicateRemovedCount: _readInt(object, 'duplicate_removed_count'),
    );
  }

  final List<QuestCandidateResponse> quests;
  final List<String> cleanedLines;
  final int duplicateRemovedCount;
}

Map<String, dynamic> _asJsonObject(Object? value, String message) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  throw FormatException(message);
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('$key must be a non-empty string.');
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : value;
  }
  throw FormatException('$key must be a string or null.');
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('$key must be a number.');
}
