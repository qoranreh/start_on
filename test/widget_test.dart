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
}
