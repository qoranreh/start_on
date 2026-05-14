import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/quest_category.dart';
import 'package:start_on/models/quest_item.dart';
import 'package:start_on/services/api_client.dart';

class NotionSyncConfig {
  const NotionSyncConfig({required this.apiToken, required this.databaseInput});

  final String apiToken;
  final String databaseInput;
}

class NotionSyncResult {
  const NotionSyncResult({
    required this.databaseId,
    required this.databaseTitle,
    required this.quests,
  });

  final String databaseId;
  final String databaseTitle;
  final List<QuestItem> quests;
}

class NotionSyncException implements Exception {
  const NotionSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotionSyncService {
  NotionSyncService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.authenticated(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<NotionSyncResult> syncDatabase(NotionSyncConfig config) async {
    final trimmedToken = config.apiToken.trim();
    final trimmedInput = config.databaseInput.trim();
    final inputId = normalizeDatabaseId(trimmedInput);
    if (trimmedToken.isEmpty) {
      throw const NotionSyncException('Notion integration secret을 입력해 주세요.');
    }
    if (inputId.isEmpty) {
      throw const NotionSyncException(
        '올바른 Notion data source ID 또는 원본 데이터베이스 URL/ID를 입력해 주세요.',
      );
    }

    await _connect(
      apiToken: trimmedToken,
      databaseInput: trimmedInput,
      normalizedInputId: inputId,
    );
    return syncSavedConnection();
  }

  Future<NotionSyncResult> syncSavedConnection() async {
    final response = await _request(
      () => _apiClient.postResponse<_NotionSyncResponse>(
        '/integrations/notion/sync',
        parseData: _NotionSyncResponse.fromJson,
        body: const <String, dynamic>{},
      ),
    );
    return _requireData(
      response,
      message: '서버 응답에 Notion 동기화 결과가 없습니다.',
    ).toResult();
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }

  Future<_NotionConnectResponse> _connect({
    required String apiToken,
    required String databaseInput,
    required String normalizedInputId,
  }) async {
    final response = await _request(
      () => _apiClient.postResponse<_NotionConnectResponse>(
        '/integrations/notion/connect',
        parseData: _NotionConnectResponse.fromJson,
        body: _connectRequestBody(
          apiToken: apiToken,
          databaseInput: databaseInput,
          normalizedInputId: normalizedInputId,
        ),
      ),
    );

    return _requireData(response, message: '서버 응답에 Notion 연결 결과가 없습니다.');
  }

  Map<String, dynamic> _connectRequestBody({
    required String apiToken,
    required String databaseInput,
    required String normalizedInputId,
  }) {
    final body = <String, dynamic>{'notion_api_token': apiToken};
    final uri = Uri.tryParse(databaseInput);
    final isUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isUrl) {
      body['database_url'] = databaseInput;
    } else {
      body['data_source_id'] = normalizedInputId;
    }
    return body;
  }

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiClientException catch (error) {
      throw NotionSyncException(_describeApiError(error));
    } on FormatException {
      throw const NotionSyncException('서버 Notion 응답을 해석하지 못했습니다.');
    }
  }

  T _requireData<T>(ApiResponse<T> response, {required String message}) {
    final data = response.data;
    if (response.success && data != null) {
      return data;
    }

    final error = response.error;
    throw NotionSyncException(error?.message ?? message);
  }

  String _describeApiError(ApiClientException error) {
    if (error.statusCode == 401) {
      return '로그인이 필요하거나 세션이 만료되었습니다. 다시 로그인해 주세요.';
    }
    return error.message;
  }

  static String normalizeDatabaseId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final match = RegExp(
      r'[0-9a-fA-F]{8}(?:-?[0-9a-fA-F]{4}){3}-?[0-9a-fA-F]{12}',
    ).firstMatch(trimmed);
    if (match == null) {
      return '';
    }

    final compact = match.group(0)!.replaceAll('-', '');
    return [
      compact.substring(0, 8),
      compact.substring(8, 12),
      compact.substring(12, 16),
      compact.substring(16, 20),
      compact.substring(20, 32),
    ].join('-');
  }
}

class _NotionConnectResponse {
  const _NotionConnectResponse({
    required this.connectionId,
    required this.databaseId,
    required this.databaseTitle,
    required this.syncStatus,
  });

  factory _NotionConnectResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Notion connection must be an object.');
    return _NotionConnectResponse(
      connectionId: _readRequiredString(object, 'connection_id'),
      databaseId: _readRequiredString(object, 'database_id'),
      databaseTitle: _readRequiredString(object, 'database_title'),
      syncStatus: _readRequiredString(object, 'sync_status'),
    );
  }

  final String connectionId;
  final String databaseId;
  final String databaseTitle;
  final String syncStatus;
}

class _NotionSyncResponse {
  const _NotionSyncResponse({
    required this.databaseId,
    required this.databaseTitle,
    required this.quests,
  });

  factory _NotionSyncResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Notion sync result must be an object.');
    final rawQuests = object['quests'] as List<dynamic>? ?? const [];
    return _NotionSyncResponse(
      databaseId: _readRequiredString(object, 'database_id'),
      databaseTitle: _readRequiredString(object, 'database_title'),
      quests: rawQuests.map(_NotionQuestCandidate.fromJson).toList(),
    );
  }

  final String databaseId;
  final String databaseTitle;
  final List<_NotionQuestCandidate> quests;

  NotionSyncResult toResult() {
    return NotionSyncResult(
      databaseId: databaseId,
      databaseTitle: databaseTitle,
      quests: [
        for (var index = 0; index < quests.length; index++)
          quests[index].toQuestItem(databaseId: databaseId, index: index),
      ],
    );
  }
}

class _NotionQuestCandidate {
  const _NotionQuestCandidate({
    required this.title,
    required this.difficulty,
    required this.category,
    required this.exp,
    required this.defaultDurationSeconds,
  });

  factory _NotionQuestCandidate.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Notion quest must be an object.');
    return _NotionQuestCandidate(
      title: _readRequiredString(object, 'title'),
      difficulty: _readRequiredString(object, 'difficulty'),
      category: _readRequiredString(object, 'category'),
      exp: _readInt(object, 'exp'),
      defaultDurationSeconds: _readInt(object, 'defaultDurationSeconds'),
    );
  }

  final String title;
  final String difficulty;
  final String category;
  final int exp;
  final int defaultDurationSeconds;

  QuestItem toQuestItem({required String databaseId, required int index}) {
    return QuestItem(
      id: 'notion:${Uri.encodeComponent('$databaseId:$index:$title')}',
      title: title,
      exp: exp,
      difficulty: questDifficultyFromApi(difficulty),
      category: normalizeQuestCategory(category),
      elapsedSeconds: 0,
      defaultDurationSeconds: defaultDurationSeconds,
    );
  }
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
