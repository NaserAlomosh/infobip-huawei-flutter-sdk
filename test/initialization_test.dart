import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/infobip_mobilemessaging_huawei_platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class InitializationPlatform extends InfobipMobileMessagingHuaweiPlatform
    with MockPlatformInterfaceMixin {
  String? applicationCode;
  Object? error;

  @override
  Stream<Object?> get events => const Stream.empty();

  @override
  Future<void> initialize({required String applicationCode}) async {
    this.applicationCode = applicationCode;
    if (error case final Object error) throw error;
  }
}

void main() {
  late InitializationPlatform platform;

  setUp(() {
    platform = InitializationPlatform();
    InfobipMobileMessagingHuaweiPlatform.instance = platform;
  });

  test('rejects an empty application code before platform delegation', () {
    expect(
      () => InfobipMobileMessagingHuawei.initialize(applicationCode: '  '),
      throwsArgumentError,
    );
    expect(platform.applicationCode, isNull);
  });

  test('delegates initialization to the platform', () async {
    await InfobipMobileMessagingHuawei.initialize(applicationCode: 'test-code');
    expect(platform.applicationCode, 'test-code');
  });

  test('completes when platform initialization succeeds', () async {
    await expectLater(
      InfobipMobileMessagingHuawei.initialize(applicationCode: 'test-code'),
      completes,
    );
  });

  test('propagates a structured platform failure', () async {
    platform.error = PlatformException(
      code: 'initialization_failed',
      message: 'Initialization failed',
    );
    await expectLater(
      InfobipMobileMessagingHuawei.initialize(applicationCode: 'test-code'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'initialization_failed',
        ),
      ),
    );
  });
}
