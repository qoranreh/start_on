import 'package:start_on/models/api_response.dart';
import 'package:start_on/models/profile_api_models.dart';
import 'package:start_on/services/api_client.dart';

class ProfileRepository {
  ProfileRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.authenticated(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<ProfileResponse> getProfile() async {
    final response = await _apiClient.getResponse<ProfileResponse>(
      '/profile',
      parseData: ProfileResponse.fromJson,
    );

    return _requireData(
      response,
      code: 'missing_profile',
      message: 'Server response did not include profile data.',
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
    throw ProfileRepositoryException(
      code: error?.code ?? code,
      message: error?.message ?? message,
    );
  }
}

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'ProfileRepositoryException($code): $message';
}
