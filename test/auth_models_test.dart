import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/auth_models.dart';

void main() {
  test('encodes email/password auth request', () {
    const request = AuthEmailPasswordRequest(
      email: ' tester@starton.local ',
      password: 'secret123',
    );

    expect(request.toJson(), {
      'email': 'tester@starton.local',
      'password': 'secret123',
    });
  });

  test('parses auth session response', () {
    final session = AuthSessionResponse.fromJson({
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'user': {'id': 'user-1', 'email': 'tester@starton.local'},
    });

    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.user.id, 'user-1');
    expect(session.user.email, 'tester@starton.local');
  });

  test('allows nullable user email and refresh token', () {
    final session = AuthSessionResponse.fromJson({
      'accessToken': 'access-token',
      'refreshToken': null,
      'user': {'id': 'user-1', 'email': null},
    });

    expect(session.refreshToken, isNull);
    expect(session.user.email, isNull);
  });

  test('rejects auth session without access token', () {
    expect(
      () => AuthSessionResponse.fromJson({
        'refreshToken': 'refresh-token',
        'user': {'id': 'user-1', 'email': 'tester@starton.local'},
      }),
      throwsFormatException,
    );
  });
}
