import 'dart:convert';
import 'dart:io';

import 'package:start_on/models/app_local_data.dart';

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

class _NotionApiException extends NotionSyncException {
  const _NotionApiException({
    required String message,
    required this.statusCode,
    required this.code,
  }) : super(message);

  final int statusCode;
  final String? code;
}

class _ResolvedNotionSource {
  const _ResolvedNotionSource({
    required this.sourceId,
    required this.sourceTitle,
    required this.pages,
  });

  final String sourceId;
  final String sourceTitle;
  final List<Map<String, dynamic>> pages;
}

class NotionSyncService {
  const NotionSyncService();

  static const _apiHost = 'api.notion.com';
  static const _apiVersion = '2026-03-11';

  Future<NotionSyncResult> syncDatabase(NotionSyncConfig config) async {
    final trimmedToken = config.apiToken.trim();
    final inputId = normalizeDatabaseId(config.databaseInput);
    if (trimmedToken.isEmpty) {
      throw const NotionSyncException('Notion integration secret을 입력해 주세요.');
    }
    if (inputId.isEmpty) {
      throw const NotionSyncException(
        '올바른 Notion data source ID 또는 원본 데이터베이스 URL/ID를 입력해 주세요.',
      );
    }
    final resolved = await _resolveSource(
      apiToken: trimmedToken,
      inputId: inputId,
    );

    return NotionSyncResult(
      databaseId: resolved.sourceId,
      databaseTitle: resolved.sourceTitle,
      quests: resolved.pages
          .where((page) => !_isCompleted(page))
          .map(_questFromPage)
          .whereType<QuestItem>()
          .toList(),
    );
  }

  Future<_ResolvedNotionSource> _resolveSource({
    required String apiToken,
    required String inputId,
  }) async {
    try {
      final dataSource = await _requestJson(
        method: 'GET',
        path: '/v1/data_sources/$inputId',
        apiToken: apiToken,
      );
      final pages = await _queryDataSource(
        apiToken: apiToken,
        dataSourceId: inputId,
      );
      return _ResolvedNotionSource(
        sourceId: inputId,
        sourceTitle: _titleFromResponse(
          dataSource,
          fallback: 'Notion Data Source',
        ),
        pages: pages,
      );
    } on _NotionApiException catch (error) {
      if (!_shouldFallbackToDatabase(error)) {
        rethrow;
      }
    }

    final database = await _requestJson(
      method: 'GET',
      path: '/v1/databases/$inputId',
      apiToken: apiToken,
    );
    final dataSourceIds = _extractDataSourceIds(database);
    if (dataSourceIds.isEmpty) {
      throw const NotionSyncException(
        '이 Notion 데이터베이스에서 읽을 수 있는 data source를 찾지 못했습니다. 원본 데이터베이스를 integration에 직접 공유했는지 확인해 주세요.',
      );
    }

    final pages = <Map<String, dynamic>>[];
    final pageIds = <String>{};
    for (final dataSourceId in dataSourceIds) {
      final results = await _queryDataSource(
        apiToken: apiToken,
        dataSourceId: dataSourceId,
      );
      for (final page in results) {
        final pageId = page['id'] as String?;
        if (pageId == null || !pageIds.add(pageId)) {
          continue;
        }
        pages.add(page);
      }
    }

    return _ResolvedNotionSource(
      sourceId: dataSourceIds.first,
      sourceTitle: _titleFromResponse(database, fallback: 'Notion Database'),
      pages: pages,
    );
  }

  bool _shouldFallbackToDatabase(_NotionApiException error) {
    return error.statusCode == 404 ||
        error.code == 'object_not_found' ||
        error.code == 'validation_error';
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

  List<String> _extractDataSourceIds(Map<String, dynamic> database) {
    final dataSources = database['data_sources'] as List<dynamic>? ?? const [];
    return dataSources
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((item) => item['id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryDataSource({
    required String apiToken,
    required String dataSourceId,
  }) async {
    final pages = <Map<String, dynamic>>[];
    String? startCursor;

    do {
      final body = <String, dynamic>{'page_size': 100};
      if (startCursor != null) {
        body['start_cursor'] = startCursor;
      }
      final response = await _requestJson(
        method: 'POST',
        path: '/v1/data_sources/$dataSourceId/query',
        apiToken: apiToken,
        body: body,
      );
      final results = (response['results'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      pages.addAll(results);
      startCursor = response['has_more'] == true
          ? response['next_cursor'] as String?
          : null;
    } while (startCursor != null);

    return pages;
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    required String apiToken,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.https(_apiHost, path));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiToken');
      request.headers.set('Notion-Version', _apiVersion);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(responseBody) as Map);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _describeError(
          statusCode: response.statusCode,
          code: decoded['code'] as String?,
          message: decoded['message'] as String?,
        );
        throw _NotionApiException(
          message: message,
          statusCode: response.statusCode,
          code: decoded['code'] as String?,
        );
      }

      return decoded;
    } on SocketException {
      throw const NotionSyncException('네트워크에 연결할 수 없어 Notion 동기화에 실패했습니다.');
    } on HandshakeException {
      throw const NotionSyncException('보안 연결에 실패했습니다. 네트워크 상태를 확인해 주세요.');
    } on FormatException {
      throw const NotionSyncException('Notion 응답을 해석하지 못했습니다.');
    } finally {
      client.close(force: true);
    }
  }

  String _describeError({
    required int statusCode,
    required String? code,
    required String? message,
  }) {
    if (statusCode == 401) {
      return 'Notion integration secret이 올바르지 않습니다.';
    }
    if (statusCode == 403) {
      return '이 data source 또는 데이터베이스에 접근할 권한이 없습니다. 원본 data source나 데이터베이스를 integration에 직접 공유했는지 확인해 주세요.';
    }
    if (statusCode == 404 || code == 'object_not_found') {
      return 'Notion data source 또는 데이터베이스를 찾지 못했습니다. data source ID 또는 원본 데이터베이스 URL/ID가 맞는지 확인해 주세요.';
    }
    if (statusCode == 400 || code == 'validation_error') {
      return '입력값 형식이 Notion data source 또는 원본 데이터베이스와 맞지 않습니다. data source ID 또는 원본 데이터베이스 URL/ID를 넣었는지 확인해 주세요.';
    }

    return message ?? 'Notion API 호출에 실패했습니다.';
  }

  String _titleFromResponse(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final titleItems = response['title'] as List<dynamic>? ?? const [];
    final title = titleItems
        .map((item) => (item as Map)['plain_text'] as String? ?? '')
        .join()
        .trim();
    return title.isEmpty ? fallback : title;
  }

  bool _isCompleted(Map<String, dynamic> page) {
    if (page['archived'] == true || page['in_trash'] == true) {
      return true;
    }

    final properties = Map<String, dynamic>.from(
      page['properties'] as Map? ?? const {},
    );
    for (final entry in properties.entries) {
      final normalizedName = _normalizeKey(entry.key);
      final property = Map<String, dynamic>.from(entry.value as Map);
      final type = property['type'] as String? ?? '';
      final isStatusField =
          normalizedName.contains('status') ||
          normalizedName.contains('done') ||
          normalizedName.contains('complete') ||
          normalizedName.contains('state') ||
          normalizedName.contains('상태') ||
          normalizedName.contains('완료');
      if (!isStatusField) {
        continue;
      }

      if (type == 'checkbox' && property['checkbox'] == true) {
        return true;
      }

      final label = _readSelectLikeName(property).toLowerCase();
      if (label.isEmpty) {
        continue;
      }

      if (label.contains('done') ||
          label.contains('complete') ||
          label.contains('completed') ||
          label.contains('finished') ||
          label.contains('closed') ||
          label.contains('완료')) {
        return true;
      }
    }

    return false;
  }

  QuestItem? _questFromPage(Map<String, dynamic> page) {
    final pageId = page['id'] as String?;
    if (pageId == null || pageId.isEmpty) {
      return null;
    }

    final properties = Map<String, dynamic>.from(
      page['properties'] as Map? ?? const {},
    );
    final title = _readTitle(properties);
    if (title.isEmpty) {
      return null;
    }

    final durationMinutes = _readDurationMinutes(properties);
    final difficulty = _readDifficulty(properties, durationMinutes);
    final category = _readCategory(properties, title);

    return QuestItem(
      id: 'notion:$pageId',
      title: title,
      exp: _readExp(properties, difficulty),
      difficulty: difficulty,
      category: category,
      elapsedSeconds: 0,
      defaultDurationSeconds: durationMinutes > 0
          ? durationMinutes * 60
          : defaultQuestDurationSecondsForDifficulty(difficulty),
    );
  }

  String _readTitle(Map<String, dynamic> properties) {
    for (final entry in properties.entries) {
      final property = Map<String, dynamic>.from(entry.value as Map);
      if (property['type'] != 'title') {
        continue;
      }

      final titleItems = property['title'] as List<dynamic>? ?? const [];
      return titleItems
          .map((item) => (item as Map)['plain_text'] as String? ?? '')
          .join()
          .trim();
    }

    return '';
  }

  int _readDurationMinutes(Map<String, dynamic> properties) {
    final property = _firstProperty(properties, const [
      'duration',
      'minutes',
      'time',
      'estimate',
      '소요시간',
      '예상시간',
    ]);
    if (property == null) {
      return 0;
    }

    final type = property['type'] as String? ?? '';
    if (type == 'number') {
      return (property['number'] as num?)?.round() ?? 0;
    }

    final rawText = _readPlainText(property);
    if (rawText.isEmpty) {
      return 0;
    }

    return _parseDurationMinutes(rawText);
  }

  String _readDifficulty(Map<String, dynamic> properties, int durationMinutes) {
    final property = _firstProperty(properties, const [
      'difficulty',
      'level',
      'priority',
      '난이도',
      '우선순위',
    ]);
    final raw = property == null ? '' : _readPlainText(property).toLowerCase();

    if (raw.contains('easy') || raw.contains('low') || raw.contains('쉬움')) {
      return '쉬움';
    }
    if (raw.contains('hard') || raw.contains('high') || raw.contains('어려움')) {
      return '어려움';
    }
    if (raw.contains('medium') || raw.contains('mid') || raw.contains('보통')) {
      return '보통';
    }

    if (durationMinutes > 0) {
      if (durationMinutes <= 30) {
        return '쉬움';
      }
      if (durationMinutes <= 60) {
        return '보통';
      }
      return '어려움';
    }

    return '보통';
  }

  String _readCategory(Map<String, dynamic> properties, String title) {
    final property = _firstProperty(properties, const [
      'category',
      'type',
      'tag',
      'area',
      '분류',
      '카테고리',
      '영역',
    ]);
    final raw = property == null ? '' : _readPlainText(property);
    final category = _mapCategory(raw);
    if (category.isNotEmpty) {
      return category;
    }
    return _mapCategory(title).isEmpty ? 'work' : _mapCategory(title);
  }

  int _readExp(Map<String, dynamic> properties, String difficulty) {
    final property = _firstProperty(properties, const ['exp', 'xp']);
    if (property != null && property['type'] == 'number') {
      final number = (property['number'] as num?)?.round();
      if (number != null && number > 0) {
        return number;
      }
    }

    return switch (difficulty) {
      '쉬움' => 30,
      '보통' => 50,
      _ => 100,
    };
  }

  Map<String, dynamic>? _firstProperty(
    Map<String, dynamic> properties,
    List<String> candidateNames,
  ) {
    for (final candidate in candidateNames) {
      final normalizedCandidate = _normalizeKey(candidate);
      for (final entry in properties.entries) {
        if (_normalizeKey(entry.key) == normalizedCandidate) {
          return Map<String, dynamic>.from(entry.value as Map);
        }
      }
    }
    return null;
  }

  String _readPlainText(Map<String, dynamic> property) {
    final type = property['type'] as String? ?? '';
    if (type == 'select' || type == 'status') {
      return _readSelectLikeName(property);
    }
    if (type == 'multi_select') {
      final values = property['multi_select'] as List<dynamic>? ?? const [];
      return values
          .map((item) => (item as Map)['name'] as String? ?? '')
          .where((item) => item.isNotEmpty)
          .join(' ');
    }
    if (type == 'rich_text') {
      final values = property['rich_text'] as List<dynamic>? ?? const [];
      return values
          .map((item) => (item as Map)['plain_text'] as String? ?? '')
          .join()
          .trim();
    }
    if (type == 'number') {
      final value = property['number'];
      return value == null ? '' : value.toString();
    }
    if (type == 'checkbox') {
      return property['checkbox'] == true ? 'true' : 'false';
    }
    return '';
  }

  String _readSelectLikeName(Map<String, dynamic> property) {
    final type = property['type'] as String? ?? '';
    final value = property[type] as Map?;
    return value == null ? '' : (value['name'] as String? ?? '');
  }

  int _parseDurationMinutes(String rawText) {
    final normalized = rawText.toLowerCase().replaceAll(' ', '');
    final hoursMatch = RegExp(r'(\d+)h').firstMatch(normalized);
    final minutesMatch = RegExp(r'(\d+)m').firstMatch(normalized);
    if (hoursMatch != null || minutesMatch != null) {
      final hours = int.tryParse(hoursMatch?.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(minutesMatch?.group(1) ?? '') ?? 0;
      return hours * 60 + minutes;
    }

    if (normalized.contains('시간')) {
      final hours = int.tryParse(
        RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '',
      );
      if (hours != null) {
        return hours * 60;
      }
    }
    if (normalized.contains('분')) {
      final minutes = int.tryParse(
        RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '',
      );
      if (minutes != null) {
        return minutes;
      }
    }

    return int.tryParse(
          RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '',
        ) ??
        0;
  }

  String _mapCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.contains('work') ||
        normalized.contains('job') ||
        normalized.contains('project') ||
        normalized.contains('업무') ||
        normalized.contains('회사')) {
      return 'work';
    }
    if (normalized.contains('study') ||
        normalized.contains('learn') ||
        normalized.contains('research') ||
        normalized.contains('공부') ||
        normalized.contains('학습')) {
      return 'study';
    }
    if (normalized.contains('life') ||
        normalized.contains('health') ||
        normalized.contains('exercise') ||
        normalized.contains('habit') ||
        normalized.contains('운동') ||
        normalized.contains('건강')) {
      return 'life';
    }
    if (normalized.contains('home') ||
        normalized.contains('todo') ||
        normalized.contains('house') ||
        normalized.contains('clean') ||
        normalized.contains('집') ||
        normalized.contains('정리')) {
      return 'home';
    }

    return '';
  }

  String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  }
}
