import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei_example/main.dart';

void main() {
  testWidgets('explains how to configure initialization', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(
      find.text('Provide INFOBIP_APPLICATION_CODE with --dart-define.'),
      findsOneWidget,
    );
    expect(find.text('Initialize SDK'), findsOneWidget);
  });
}
