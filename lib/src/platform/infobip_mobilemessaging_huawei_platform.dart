import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_infobip_mobilemessaging_huawei.dart';
import '../user/user.dart';

abstract class InfobipMobileMessagingHuaweiPlatform extends PlatformInterface {
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

  Future<void> initialize({required String applicationCode});

  Future<void> setRegistration({required bool enabled});

  Future<bool> isRegistrationEnabled();

  Future<User> getUser() => throw UnimplementedError();
  Future<User> fetchUser() => throw UnimplementedError();
  Future<User> saveUser(User user) => throw UnimplementedError();
  Future<User> personalize(
    UserIdentity userIdentity,
    UserAttributes? userAttributes, {
    required bool forceDepersonalize,
  }) => throw UnimplementedError();
  Future<void> depersonalize() => throw UnimplementedError();
}
