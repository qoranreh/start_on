import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/quest_generation_api_models.dart';
import 'package:start_on/repositories/quest_text_extraction_repository.dart';
import 'package:start_on/services/api_client.dart';

void main() {
  test('OCRTextQuestExtractionResponse parses server payload', () {
    final response = OCRTextQuestExtractionResponse.fromJson({
      'quests': [
        {
          'title': '자료구조 공부',
          'difficulty': 'normal',
          'category': 'study',
          'exp': 50,
          'defaultDurationSeconds': 2700,
          'reason': 'Generated from cleaned OCR text.',
        },
      ],
      'cleaned_lines': ['자료구조 공부'],
      'duplicate_removed_count': 1,
    });

    expect(response.quests.single.title, '자료구조 공부');
    expect(response.quests.single.defaultDurationSeconds, 2700);
    expect(response.cleanedLines, ['자료구조 공부']);
    expect(response.duplicateRemovedCount, 1);
  });

  test('extract posts OCR text to server endpoint', () async {
    final apiClient = _FakeTextExtractionApiClient(
      const ApiResponse<OCRTextQuestExtractionResponse>(
        success: true,
        data: OCRTextQuestExtractionResponse(
          quests: [
            QuestCandidateResponse(
              title: '자료구조 공부',
              difficulty: 'normal',
              category: 'study',
              exp: 50,
              defaultDurationSeconds: 2700,
              reason: 'Generated from cleaned OCR text.',
            ),
          ],
          cleanedLines: ['자료구조 공부'],
          duplicateRemovedCount: 1,
        ),
        error: null,
      ),
    );
    final repository = QuestTextExtractionRepository(apiClient: apiClient);

    final response = await repository.extract('자료구조 공부\n자료구조 공부');

    expect(apiClient.requests.single.path, '/quests/from-text');
    expect(apiClient.requests.single.body, {'raw_text': '자료구조 공부\n자료구조 공부'});
    expect(response.quests.single.category, 'study');
    expect(response.duplicateRemovedCount, 1);
  });

  test('throws repository exception when response has no data', () async {
    final apiClient = _FakeTextExtractionApiClient(
      const ApiResponse<OCRTextQuestExtractionResponse>(
        success: true,
        data: null,
        error: null,
      ),
    );
    final repository = QuestTextExtractionRepository(apiClient: apiClient);

    expect(
      () => repository.extract('할 일'),
      throwsA(isA<QuestTextExtractionRepositoryException>()),
    );
  });
}

class _FakeTextExtractionApiClient extends ApiClient {
  _FakeTextExtractionApiClient(this.response)
    : super(baseUrl: 'http://localhost');

  final ApiResponse<dynamic> response;
  final List<_CapturedRequest> requests = [];

  @override
  Future<ApiResponse<T>> postResponse<T>(
    String path, {
    required ApiDataParser<T> parseData,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    requests.add(_CapturedRequest(path: path, body: body));
    return response as ApiResponse<T>;
  }
}

class _CapturedRequest {
  const _CapturedRequest({required this.path, this.body});

  final String path;
  final Object? body;
}
