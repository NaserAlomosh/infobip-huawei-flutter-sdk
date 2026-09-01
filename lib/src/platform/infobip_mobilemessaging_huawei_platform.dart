import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_infobip_mobilemessaging_huawei.dart';

abstract class InfobipMobileMessagingHuaweiPlatform
    extends PlatformInterface {
  InfobipMobileMessagingHuaweiPlatform() : super(token: _token);

  static final Object _token = Object();

  static InfobipMobileMessagingHuaweiPlatform _instance =
      MethodChannelInfobipMobileMessagingHuawei();

  static InfobipMobileMessagingHuaweiPlatform get instance => _instance;

  static set instance(InfobipMobileMessagingHuaweiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<Object?> get events;
}
