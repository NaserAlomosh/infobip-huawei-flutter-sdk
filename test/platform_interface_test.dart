import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/channel_contract.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/infobip_mobilemessaging_huawei_platform.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/method_channel_infobip_mobilemessaging_huawei.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class FakePlatform extends InfobipMobileMessagingHuaweiPlatform
    with MockPlatformInterfaceMixin {
  String? initializedWith;

  @override
  Stream<Object?> get events => const Stream.empty();

  @override
  Future<void> initialize({required String applicationCode}) async {
    initializedWith = applicationCode;
  }

  @override
  Future<bool> isRegistrationEnabled() async => false;

  @override
  Future<void> setRegistration({required bool enabled}) async {}
}

void main() {
  test('uses the method-channel implementation by default', () {
    expect(
      InfobipMobileMessagingHuaweiPlatform.instance,
      isA<MethodChannelInfobipMobileMessagingHuawei>(),
    );
  });

  test('allows a verified platform implementation', () {
    final platform = FakePlatform();
    InfobipMobileMessagingHuaweiPlatform.instance = platform;
    expect(InfobipMobileMessagingHuaweiPlatform.instance, same(platform));
  });

  test('centralizes stable channel names', () {
    expect(
      ChannelContract.methodChannel,
      'com.infobip.mobilemessaging.huawei/methods',
    );
    expect(
      ChannelContract.eventChannel,
      'com.infobip.mobilemessaging.huawei/events',
    );
  });
}
