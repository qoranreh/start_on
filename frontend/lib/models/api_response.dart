typedef ApiDataParser<T> = T Function(Object? json);
typedef ApiDataEncoder<T> = Object? Function(T data);

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    required this.error,
  });

  factory ApiResponse.fromJson(Object? json, ApiDataParser<T> parseData) {
    final object = _asJsonObject(json, 'API response must be a JSON object.');

    final success = object['success'];
    if (success is! bool) {
      throw const FormatException('API response success must be a boolean.');
    }

    final rawData = object['data'];
    return ApiResponse<T>(
      success: success,
      data: rawData == null ? null : parseData(rawData),
      error: object['error'] == null
          ? null
          : ApiError.fromJson(object['error']),
    );
  }

  final bool success;
  final T? data;
  final ApiError? error;

  bool get hasData => data != null;

  ApiResponse<R> mapData<R>(R Function(T data) convert) {
    final currentData = data;
    return ApiResponse<R>(
      success: success,
      data: currentData == null ? null : convert(currentData),
      error: error,
    );
  }

  Map<String, dynamic> toJson(ApiDataEncoder<T> encodeData) {
    final currentData = data;
    return {
      'success': success,
      'data': currentData == null ? null : encodeData(currentData),
      'error': error?.toJson(),
    };
  }
}

class ApiError {
  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Object? json) {
    if (json == null) {
      return const ApiError(
        code: 'unknown_error',
        message: 'Unknown API error.',
      );
    }
    if (json is String) {
      return ApiError(code: 'api_error', message: json);
    }

    final object = _asJsonObject(json, 'API error must be a JSON object.');
    return ApiError(
      code: _readString(object, 'code', 'unknown_error'),
      message: _readString(object, 'message', 'Unknown API error.'),
    );
  }

  final String code;
  final String message;

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message};
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

String _readString(Map<String, dynamic> json, String key, String fallback) {
  final value = json[key];
  return value is String && value.trim().isNotEmpty ? value : fallback;
}
