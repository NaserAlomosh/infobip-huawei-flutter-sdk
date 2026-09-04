import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_infobip_mobilemessaging_huawei.dart';
import '../user/user.dart';
import '../installation/installation.dart';
import '../inbox/inbox.dart';

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

  Future<void> registerForRemoteNotifications() => throw UnimplementedError();

  Future<int> getChatUnreadMessageCount() => throw UnimplementedError();

  Future<User> getUser() => throw UnimplementedError();

  Future<User> fetchUser() => throw UnimplementedError();

  Future<User> saveUser(User user) => throw UnimplementedError();

  Future<User> personalize(
    UserIdentity userIdentity,
    UserAttributes? userAttributes, {
    required bool forceDepersonalize,
  }) => throw UnimplementedError();

  Future<void> depersonalize() => throw UnimplementedError();

  Future<void> setJwt(String? jwt) => throw UnimplementedError();

  Future<Installation> getInstallation() => throw UnimplementedError();

  Future<Installation> fetchInstallation() => throw UnimplementedError();

  Future<Installation> saveInstallation(Installation installation) =>
      throw UnimplementedError();

  Future<Inbox> fetchInbox({
    required String externalUserId,
    String? jwt,
    InboxFilterOptions? options,
  }) => throw UnimplementedError();

  Future<void> setInboxMessagesSeen({
    required String externalUserId,
    required List<String> messageIds,
  }) => throw UnimplementedError();
}
