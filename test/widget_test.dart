import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/main.dart';

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('FlapMail'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}