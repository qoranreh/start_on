import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/stats_api_models.dart';
import 'package:start_on/services/api_client.dart';

class StatsRepository {
  StatsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.authenticated(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<StatsSummaryResponse> getSummary() async {
    final response = await _apiClient.getResponse<StatsSummaryResponse>(
      '/stats/summary',
      parseData: StatsSummaryResponse.fromJson,
    );

    return _requireData(
      response,
      code: 'missing_stats_summary',
      message: 'Server response did not include stats summary data.',
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
    throw StatsRepositoryException(
      code: error?.code ?? code,
      message: error?.message ?? message,
    );
  }
}

class StatsRepositoryException implements Exception {
  const StatsRepositoryException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'StatsRepositoryException($code): $message';
}
