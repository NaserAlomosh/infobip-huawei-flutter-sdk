import 'package:flutter/services.dart';

import 'channel_contract.dart';
import 'infobip_mobilemessaging_huawei_platform.dart';
import '../user/user.dart';
import '../user/user_codec.dart';
import '../installation/installation.dart';
import '../installation/installation_codec.dart';
import '../inbox/inbox.dart';
import '../inbox/inbox_codec.dart';

final class MethodChannelInfobipMobileMessagingHuawei
    extends InfobipMobileMessagingHuaweiPlatform {
  MethodChannelInfobipMobileMessagingHuawei({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : methodChannel =
           methodChannel ?? const MethodChannel(ChannelContract.methodChannel),
       eventChannel =
           eventChannel ?? const EventChannel(ChannelContract.eventChannel) {
    _events = this.eventChannel.receiveBroadcastStream();
  }

  final MethodChannel methodChannel;
  final EventChannel eventChannel;
  late final Stream<Object?> _events;

  @override
  Stream<Object?> get events => _events;

  @override
  Future<void> initialize({required String applicationCode}) async {
    await methodChannel.invokeMethod<void>(ChannelContract.initialize, {
      ChannelContract.applicationCode: applicationCode,
    });
  }

  @override
  Future<void> setRegistration({required bool enabled}) async {
    await methodChannel.invokeMethod<void>(ChannelContract.setRegistration, {
      ChannelContract.enabled: enabled,
    });
  }

  @override
  Future<bool> isRegistrationEnabled() async {
    return await methodChannel.invokeMethod<bool>(
          ChannelContract.isRegistrationEnabled,
        ) ??
        false;
  }

  @override
  Future<User> getUser() async => UserCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.getUser),
  );

  @override
  Future<User> fetchUser() async => UserCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.fetchUser),
  );

  @override
  Future<User> saveUser(User user) async => UserCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.saveUser, {
      ChannelContract.user: UserCodec.encode(user),
    }),
  );

  @override
  Future<User> personalize(
    UserIdentity userIdentity,
    UserAttributes? userAttributes, {
    required bool forceDepersonalize,
  }) async => UserCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.personalize, {
      ChannelContract.userIdentity: UserCodec.encodeIdentity(userIdentity),
      ChannelContract.userAttributes: userAttributes == null
          ? null
          : UserCodec.encodeAttributes(userAttributes),
      ChannelContract.forceDepersonalize: forceDepersonalize,
    }),
  );

  @override
  Future<void> depersonalize() =>
      methodChannel.invokeMethod<void>(ChannelContract.depersonalize);

  @override
  Future<Installation> getInstallation() async => InstallationCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.getInstallation),
  );

  @override
  Future<Installation> fetchInstallation() async => InstallationCodec.decode(
    await methodChannel.invokeMethod<Object?>(ChannelContract.fetchInstallation),
  );

  @override
  Future<Installation> saveInstallation(Installation installation) async =>
      InstallationCodec.decode(
        await methodChannel.invokeMethod<Object?>(ChannelContract.saveInstallation, {
          ChannelContract.installation: InstallationCodec.encodeWritable(installation),
        }),
      );

  @override
  Future<Inbox> fetchInbox(InboxFilterOptions? options) async =>
      InboxCodec.decode(
        await methodChannel.invokeMethod<Object?>(ChannelContract.fetchInbox, {
          ChannelContract.options: InboxCodec.encodeOptions(options),
        }),
      );

  @override
  Future<void> setInboxMessagesSeen(List<String> messageIds) =>
      methodChannel.invokeMethod<void>(ChannelContract.setInboxMessagesSeen, {
        ChannelContract.messageIds: messageIds,
      });
}
