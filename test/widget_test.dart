import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:start_on/app_shell.dart';
import 'package:start_on/models/auth_models.dart';
import 'package:start_on/repositories/auth_repository.dart';
import 'package:start_on/services/api_client.dart';

void main() {
  testWidgets('renders login screen first', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AdFocusApp());
    await tester.pumpAndSettle();

    expect(find.text('START ON'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
    expect(find.text('게스트로 시작'), findsOneWidget);
  });

  testWidgets('renders home shell for saved session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth.is_signed_in': true,
      'auth.user_id': 'user-1',
      'auth.email': 'tester@starton.local',
      'auth.display_name': 'Tester',
      'auth.access_token': 'access-token',
      'settings.notifications_enabled': false,
    });

    await tester.pumpWidget(const AdFocusApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tester 님'), findsOneWidget);
    expect(find.text('오늘의 퀘스트'), findsWidgets);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
  });

  testWidgets('guest start saves a local session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.notifications_enabled': false,
    });

    await tester.pumpWidget(const AdFocusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('게스트로 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auth.is_signed_in'), isTrue);
    expect(prefs.getString('auth.user_id'), 'local:guest@starton.local');
    expect(prefs.getString('auth.email'), 'guest@starton.local');
    expect(prefs.getString('auth.display_name'), '게스트');
    expect(prefs.getString('auth.access_token'), '');
    expect(prefs.getBool('auth.is_local_only'), isTrue);
    expect(find.text('게스트 님'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AdFocusApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('START ON'), findsNothing);
    expect(find.text('게스트 님'), findsOneWidget);
  });

  testWidgets('server login saves auth repository session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.notifications_enabled': false,
    });
    final repository = _FakeAuthRepository(
      response: const AuthSessionResponse(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        user: AuthUserResponse(id: 'user-1', email: 'tester@starton.local'),
      ),
    );

    await tester.pumpWidget(AdFocusApp(authRepository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'tester@starton.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(repository.email, 'tester@starton.local');
    expect(repository.password, 'secret123');
    expect(prefs.getBool('auth.is_signed_in'), isTrue);
    expect(prefs.getString('auth.user_id'), 'user-1');
    expect(prefs.getString('auth.email'), 'tester@starton.local');
    expect(prefs.getString('auth.access_token'), 'access-token');
    expect(prefs.getString('auth.refresh_token'), 'refresh-token');
    expect(prefs.getBool('auth.is_local_only'), isFalse);
    expect(find.text('Tester 님'), findsOneWidget);
  });

  testWidgets('server sign up saves auth repository session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.notifications_enabled': false,
    });
    final repository = _FakeAuthRepository(
      response: const AuthSessionResponse(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        user: AuthUserResponse(id: 'new-user-1', email: 'new@starton.local'),
      ),
    );

    await tester.pumpWidget(AdFocusApp(authRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가입'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'new@starton.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(repository.lastAuthAction, _AuthAction.signUp);
    expect(repository.email, 'new@starton.local');
    expect(repository.password, 'secret123');
    expect(prefs.getBool('auth.is_signed_in'), isTrue);
    expect(prefs.getString('auth.user_id'), 'new-user-1');
    expect(prefs.getString('auth.email'), 'new@starton.local');
    expect(prefs.getString('auth.access_token'), 'new-access-token');
    expect(prefs.getString('auth.refresh_token'), 'new-refresh-token');
    expect(find.text('New 님'), findsOneWidget);
  });

  testWidgets('server login error keeps login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeAuthRepository(
      error: const AuthRepositoryException(
        code: 'supabase_auth_failed',
        message: 'Invalid login credentials',
      ),
    );

    await tester.pumpWidget(AdFocusApp(authRepository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'tester@starton.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auth.is_signed_in'), isNull);
    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(find.text('START ON'), findsOneWidget);
  });

  testWidgets('sign up confirmation error keeps login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeAuthRepository(
      error: ApiClientException(
        statusCode: 400,
        code: 'signup_requires_confirmation',
        message: 'Email confirmation is required.',
      ),
    );

    await tester.pumpWidget(AdFocusApp(authRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가입'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'new@starton.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(repository.lastAuthAction, _AuthAction.signUp);
    expect(prefs.getBool('auth.is_signed_in'), isNull);
    expect(
      find.text('가입은 접수됐지만 이메일 확인이 필요해요. 메일 확인 후 로그인해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('START ON'), findsOneWidget);
  });
}

enum _AuthAction { signIn, signUp }

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.response, this.error})
    : super(apiClient: _UnusedApiClient());

  final AuthSessionResponse? response;
  final Object? error;
  String? email;
  String? password;
  _AuthAction? lastAuthAction;

  @override
  Future<AuthSessionResponse> signIn({
    required String email,
    required String password,
  }) async {
    lastAuthAction = _AuthAction.signIn;
    this.email = email;
    this.password = password;

    final error = this.error;
    if (error != null) {
      throw error;
    }

    return response!;
  }

  @override
  Future<AuthSessionResponse> signUp({
    required String email,
    required String password,
  }) async {
    lastAuthAction = _AuthAction.signUp;
    this.email = email;
    this.password = password;

    final error = this.error;
    if (error != null) {
      throw error;
    }

    return response!;
  }

  @override
  void close() {}
}

class _UnusedApiClient extends ApiClient {
  _UnusedApiClient() : super(baseUrl: 'http://localhost');
}
