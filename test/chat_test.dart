import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('controller is safe before attachment', () async {
    final controller = InfobipHuaweiChatController();

    expect(controller.isAttached, isFalse);
    expect(await controller.navigateBackOrCloseChat(), isFalse);
  });

  testWidgets('unsupported platforms render a deterministic placeholder', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: InfobipHuaweiChatView(),
      ),
    );

    expect(find.text('Chat is available on Android only.'), findsOneWidget);
  });
}
