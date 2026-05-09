import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:start_on/services/api_client.dart';
import 'package:start_on/storage/auth_session_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'authenticated client sends saved access token as Bearer header',
    () async {
      await const AuthSessionStore().save(
        const AuthSession(
          userId: 'user-1',
          email: 'tester@starton.local',
          displayName: 'Tester',
          accessToken: ' access-token ',
        ),
      );

      final capturedHeaders = <String, String>{};
      final apiClient = ApiClient.authenticated(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          capturedHeaders.addAll(request.headers);
          return _okResponse();
        }),
      );

      await apiClient.get('/profile');

      expect(capturedHeaders['Authorization'], 'Bearer access-token');
    },
  );

  test(
    'authenticated client omits Authorization header for local-only session',
    () async {
      await const AuthSessionStore().save(
        AuthSession.local(email: 'guest@starton.local', displayName: '게스트'),
      );

      final capturedHeaders = <String, String>{};
      final apiClient = ApiClient.authenticated(
        baseUrl: 'http://localhost/api/v1',
        httpClient: MockClient((request) async {
          capturedHeaders.addAll(request.headers);
          return _okResponse();
        }),
      );

      await apiClient.get('/profile');

      expect(capturedHeaders.containsKey('Authorization'), isFalse);
    },
  );
}

http.Response _okResponse() {
  return http.Response(
    jsonEncode({
      'success': true,
      'data': {'ok': true},
      'error': null,
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}
