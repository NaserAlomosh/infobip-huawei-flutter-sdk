import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('controller is safe before attachment', () async {
    final controller = InfobipHuaweiChatController();

    expect(controller.isAttached, isFalse);
    expect(await controller.navigateBackOrCloseChat(), isFalse);
    await expectLater(
      controller.send(
        const InfobipHuaweiChatMessagePayload.text('Hello'),
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'chat_unavailable',
        ),
      ),
    );
    await expectLater(
      controller.sendContextualData('{"source":"support"}'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      controller.getLanguage(),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      controller.getWidgetTheme(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('text payload rejects empty text', () {
    expect(
      () => const InfobipHuaweiChatMessagePayload.text('  ').toMap(),
      throwsArgumentError,
    );
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

    testWidgets('controller sends text on its view channel', (tester) async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await controller.send(
        const InfobipHuaweiChatMessagePayload.text('Hello'),
      );

      expect(calls.last.method, 'send');
      expect(calls.last.arguments, <String, Object>{'text': 'Hello'});
    });

    testWidgets('controller sends contextual data on its view channel', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await controller.sendContextualData('{"source":"support"}');

      expect(calls.last.method, 'sendContextualData');
      expect(calls.last.arguments, <String, Object>{
        'data': '{"source":"support"}',
      });
    });

    testWidgets('controller sets and gets the component language', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return call.method == 'getLanguage' ? 'en-US' : null;
      });
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await controller.setLanguage('en-US');

      expect(calls.last.method, 'setLanguage');
      expect(calls.last.arguments, <String, Object>{'language': 'en-US'});
      expect(await controller.getLanguage(), 'en-US');
    });

    testWidgets('controller sets and gets the widget theme', (tester) async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return call.method == 'getWidgetTheme' ? 'support' : null;
      });
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await controller.setWidgetTheme('support');

      expect(calls.last.method, 'setWidgetTheme');
      expect(calls.last.arguments, <String, Object>{
        'widgetTheme': 'support',
      });
      expect(await controller.getWidgetTheme(), 'support');
    });

    testWidgets('controller preserves an absent widget theme', (tester) async {
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      expect(await controller.getWidgetTheme(), isNull);
    });

    testWidgets('navigation rejects a missing native boolean', (tester) async {
      messenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (_) async => null,
      );
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await expectLater(
        controller.navigateBackOrCloseChat(),
        throwsFormatException,
      );
    });

    testWidgets('controller validates language and theme values', (
      tester,
    ) async {
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await expectLater(controller.setLanguage(' '), throwsArgumentError);
      await expectLater(controller.setLanguage(''), throwsArgumentError);
      await expectLater(controller.setWidgetTheme(' '), throwsArgumentError);
    });

    testWidgets('controller command forwards a native error', (tester) async {
      messenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async => throw PlatformException(code: 'native_error'),
      );
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);

      await expectLater(
        controller.send(
          const InfobipHuaweiChatMessagePayload.text('Hello'),
        ),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'native_error',
          ),
        ),
      );
    });

    testWidgets('disposed controller rejects commands', (tester) async {
      final controller = InfobipHuaweiChatController();
      await mountView(tester, controller: controller);
      await tester.pumpWidget(const SizedBox());

      await expectLater(
        controller.sendContextualData('{}'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
