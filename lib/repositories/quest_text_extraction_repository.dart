import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/quest_generation_api_models.dart';
import 'package:start_on/services/api_client.dart';

class QuestTextExtractionRepository {
  QuestTextExtractionRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<OCRTextQuestExtractionResponse> extract(String rawText) async {
    final response = await _apiClient
        .postResponse<OCRTextQuestExtractionResponse>(
          '/quests/from-text',
          body: {'raw_text': rawText},
          parseData: OCRTextQuestExtractionResponse.fromJson,
        );

    return _requireData(
      response,
      code: 'missing_ocr_text_extraction',
      message: 'Server response did not include OCR text extraction data.',
    );
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }

  T _requireData<T>(
    ApiResponse<T> response, {
    required String code,
    required String message,
  }) {
    final data = response.data;
    if (response.success && data != null) {
      return data;
    }

    final error = response.error;
    throw QuestTextExtractionRepositoryException(
      code: error?.code ?? code,
      message: error?.message ?? message,
    );
  }
}

class QuestTextExtractionRepositoryException implements Exception {
  const QuestTextExtractionRepositoryException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() =>
      'QuestTextExtractionRepositoryException($code): $message';
}
