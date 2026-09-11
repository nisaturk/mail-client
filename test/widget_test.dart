import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/main.dart';
import 'package:flapmail/presentation/screens/compose_screen.dart';
import 'package:flapmail/presentation/screens/home_screen.dart';

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('FlapMail'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('home shows the inbox on a phone-sized surface',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Proje Teslim Tarihi'), findsOneWidget);
    expect(find.text('Mehmet Yilmaz'), findsOneWidget);
  });

  testWidgets('opening a mail shows the detail header',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Fatura - Ağustos 2025'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
  });

  testWidgets('compose renders on a narrow phone surface',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ComposeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
  });
}