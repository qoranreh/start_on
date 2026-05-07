import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:start_on/app_shell.dart';

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
      'auth.email': 'tester@starton.local',
      'auth.display_name': 'Tester',
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
    expect(prefs.getString('auth.email'), 'guest@starton.local');
    expect(prefs.getString('auth.display_name'), '게스트');
    expect(find.text('게스트 님'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AdFocusApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('START ON'), findsNothing);
    expect(find.text('게스트 님'), findsOneWidget);
  });
}
