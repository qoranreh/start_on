class AuthEmailPasswordRequest {
  const AuthEmailPasswordRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {'email': email.trim(), 'password': password};
  }
}

class AuthUserResponse {
  const AuthUserResponse({required this.id, required this.email});

  factory AuthUserResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Auth user must be a JSON object.');

    return AuthUserResponse(
      id: _readRequiredString(object, 'id'),
      email: _readOptionalString(object, 'email'),
    );
  }

  final String id;
  final String? email;

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }
}

class AuthSessionResponse {
  const AuthSessionResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSessionResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Auth session must be a JSON object.');

    return AuthSessionResponse(
      accessToken: _readRequiredString(object, 'accessToken'),
      refreshToken: _readOptionalString(object, 'refreshToken'),
      user: AuthUserResponse.fromJson(object['user']),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final AuthUserResponse user;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
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
