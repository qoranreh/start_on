import 'package:flutter_test/flutter_test.dart';
import 'package:start_on/models/api_response.dart';

void main() {
  test('parses a typed success response', () {
    final response = ApiResponse<Map<String, dynamic>>.fromJson({
      'success': true,
      'data': {'id': 'user-1', 'email': 'tester@starton.local'},
      'error': null,
    }, (json) => Map<String, dynamic>.from(json as Map));

    expect(response.success, isTrue);
    expect(response.error, isNull);
    expect(response.data?['id'], 'user-1');
    expect(response.data?['email'], 'tester@starton.local');
  });

  test('parses an error response', () {
    final response = ApiResponse<Object>.fromJson({
      'success': false,
      'data': null,
      'error': {
        'code': 'missing_authorization',
        'message': 'Authorization header is required.',
      },
    }, (json) => json as Object);

    expect(response.success, isFalse);
    expect(response.data, isNull);
    expect(response.error?.code, 'missing_authorization');
    expect(response.error?.message, 'Authorization header is required.');
  });

  test('rejects an invalid response envelope', () {
    expect(
      () => ApiResponse<Object>.fromJson({
        'data': null,
        'error': null,
      }, (json) => json as Object),
      throwsFormatException,
    );
  });
}
