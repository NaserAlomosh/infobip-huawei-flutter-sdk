import 'package:flutter/services.dart';
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

  group('embedded Chat errors', () {
    const viewId = 42;
    const channelName = 'com.infobip.mobilemessaging.huawei/chat_view/42';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    Future<void> mountView(
      WidgetTester tester, {
      InfobipHuaweiChatController? controller,
      void Function(InfobipHuaweiChatError)? onError,
    }) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InfobipHuaweiChatView(
            controller: controller,
            onError: onError,
          ),
        ),
      );
      tester.widget<AndroidView>(find.byType(AndroidView)).onPlatformViewCreated(
        viewId,
      );
      await tester.pump();
    }

    Future<void> emitError(Object? payload) async {
      final data = const StandardMethodCodec().encodeMethodCall(
        MethodCall('onError', payload),
      );
      await messenger.handlePlatformMessage(channelName, data, (_) {});
    }

    setUp(() {
      messenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async => call.method == 'navigateBackOrCloseChat' ? true : null,
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    for (final entry in <String, InfobipHuaweiChatErrorCode>{
      'not_initialized': InfobipHuaweiChatErrorCode.notInitialized,
      'activity_unavailable': InfobipHuaweiChatErrorCode.activityUnavailable,
      'chat_unavailable': InfobipHuaweiChatErrorCode.chatUnavailable,
      'native_error': InfobipHuaweiChatErrorCode.nativeError,
      'future_error': InfobipHuaweiChatErrorCode.unknown,
    }.entries) {
      testWidgets('decodes ${entry.key}', (tester) async {
        InfobipHuaweiChatError? received;
        await mountView(tester, onError: (error) => received = error);

        await emitError({'code': entry.key, 'message': 'Unavailable'});

        expect(received?.code, entry.value);
        expect(received?.message, 'Unavailable');
      });
    }

    testWidgets('malformed payload maps to unknown', (tester) async {
      InfobipHuaweiChatError? received;
      await mountView(tester, onError: (error) => received = error);

      await emitError('invalid');

      expect(received?.code, InfobipHuaweiChatErrorCode.unknown);
      expect(received?.message, isNull);
    });

    testWidgets('does not invoke callback after disposal', (tester) async {
      var calls = 0;
      await mountView(tester, onError: (_) => calls++);
      await tester.pumpWidget(const SizedBox());

      await emitError({'code': 'not_initialized'});

      expect(calls, 0);
    });

    testWidgets('controller shares the view bridge channel', (tester) async {
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      expect(controller.isAttached, isTrue);
      expect(await controller.navigateBackOrCloseChat(), isTrue);
    });
  });
}
