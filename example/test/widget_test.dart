import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei_example/app.dart';
import 'package:infobip_mobilemessaging_huawei_example/screens/home_screen.dart';
import 'package:infobip_mobilemessaging_huawei_example/widgets/result_card.dart';

void main() {
  testWidgets('explains missing application-code configuration', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.textContaining('Provide INFOBIP_APPLICATION_CODE'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('home navigates to each feature example', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          initializationState: InitializationState.initialized,
          applicationCodeConfigured: true,
          onInitialize: () {},
        ),
      ),
    );

    for (final title in ['Notifications', 'User', 'Installation', 'Inbox', 'Chat']) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(find.text('Read user'), findsOneWidget);
  });

  testWidgets('result card presents a persistent result', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResultCard(title: 'Result', message: 'Safe value')),
      ),
    );

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Safe value'), findsOneWidget);
  });
}
