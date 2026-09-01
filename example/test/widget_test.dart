import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei_example/main.dart';

void main() {
  testWidgets('shows the Phase 1 integration status', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Plugin infrastructure is ready.'), findsOneWidget);
  });
}
