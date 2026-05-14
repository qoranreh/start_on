import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/api_response.dart';
import 'package:start_on/services/api_client.dart';
import 'package:start_on/services/notion_sync_service.dart';

void main() {
  test('syncDatabase connects then syncs through backend endpoints', () async {
    final apiClient = _FakeNotionApiClient([
      _successData({
        'connection_id': 'connection-1',
        'database_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
        'database_title': 'Tasks',
        'sync_status': 'active',
      }),
      _successData({
        'database_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
        'database_title': 'Tasks',
        'quests': [
          {
            'title': 'Study sockets',
            'difficulty': 'normal',
            'category': 'study',
            'exp': 50,
            'defaultDurationSeconds': 2700,
          },
        ],
      }),
    ]);
    final service = NotionSyncService(apiClient: apiClient);

    final result = await service.syncDatabase(
      const NotionSyncConfig(
        apiToken: ' notion-secret ',
        databaseInput:
            'https://www.notion.so/Tasks-35bdd41fce07815292aedabdfc826f3b',
      ),
    );

    expect(apiClient.requests[0].path, '/integrations/notion/connect');
    expect(apiClient.requests[0].body, {
      'notion_api_token': 'notion-secret',
      'database_url':
          'https://www.notion.so/Tasks-35bdd41fce07815292aedabdfc826f3b',
    });
    expect(apiClient.requests[1].path, '/integrations/notion/sync');
    expect(apiClient.requests[1].body, const <String, dynamic>{});
    expect(result.databaseTitle, 'Tasks');
    expect(result.quests.single.title, 'Study sockets');
    expect(result.quests.single.difficulty, '보통');
    expect(result.quests.single.category, 'study');
    expect(result.quests.single.id, startsWith('notion:'));
  });

  test('syncDatabase sends UUID input as data source id', () async {
    final apiClient = _FakeNotionApiClient([
      _successData({
        'connection_id': 'connection-1',
        'database_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
        'database_title': 'Tasks',
        'sync_status': 'active',
      }),
      _successData({
        'database_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
        'database_title': 'Tasks',
        'quests': const [],
      }),
    ]);
    final service = NotionSyncService(apiClient: apiClient);

    await service.syncDatabase(
      const NotionSyncConfig(
        apiToken: 'notion-secret',
        databaseInput: '35bdd41fce07815292aedabdfc826f3b',
      ),
    );

    expect(apiClient.requests.first.body, {
      'notion_api_token': 'notion-secret',
      'data_source_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
    });
  });

  test('syncSavedConnection uses saved server connection', () async {
    final apiClient = _FakeNotionApiClient([
      _successData({
        'database_id': '35bdd41f-ce07-8152-92ae-dabdfc826f3b',
        'database_title': 'Tasks',
        'quests': const [],
      }),
    ]);
    final service = NotionSyncService(apiClient: apiClient);

    final result = await service.syncSavedConnection();

    expect(apiClient.requests.single.path, '/integrations/notion/sync');
    expect(apiClient.requests.single.body, const <String, dynamic>{});
    expect(result.databaseId, '35bdd41f-ce07-8152-92ae-dabdfc826f3b');
  });
}

Map<String, dynamic> _successData(Map<String, dynamic> data) {
  return {'success': true, 'data': data, 'error': null};
}

class _FakeNotionApiClient extends ApiClient {
  _FakeNotionApiClient(this.responses) : super(baseUrl: 'http://localhost');

  final List<Object?> responses;
  final List<_CapturedRequest> requests = [];

  @override
  Future<ApiResponse<T>> postResponse<T>(
    String path, {
    required ApiDataParser<T> parseData,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    requests.add(_CapturedRequest(path: path, body: body));
    return ApiResponse<T>.fromJson(responses.removeAt(0), parseData);
  }
}

class _CapturedRequest {
  const _CapturedRequest({required this.path, this.body});

  final String path;
  final Object? body;
}
