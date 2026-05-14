import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/dungeon_api_models.dart';
import 'package:start_on/services/api_client.dart';

class DungeonRepository {
  DungeonRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.authenticated(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<DungeonListResponse> listDungeons() async {
    final response = await _apiClient.getResponse<DungeonListResponse>(
      '/dungeons',
      parseData: DungeonListResponse.fromJson,
    );

    return _requireData(
      response,
      code: 'missing_dungeon_list',
      message: 'Server response did not include dungeon list data.',
    );
  }

  Future<DungeonClearResponse> clearDungeon(String dungeonId) async {
    final response = await _apiClient.postResponse<DungeonClearResponse>(
      '/dungeons/${Uri.encodeComponent(dungeonId)}/clear',
      parseData: DungeonClearResponse.fromJson,
    );

    return _requireData(
      response,
      code: 'missing_dungeon_clear_result',
      message: 'Server response did not include dungeon clear data.',
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
    throw DungeonRepositoryException(
      code: error?.code ?? code,
      message: error?.message ?? message,
    );
  }
}

class DungeonRepositoryException implements Exception {
  const DungeonRepositoryException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'DungeonRepositoryException($code): $message';
}
