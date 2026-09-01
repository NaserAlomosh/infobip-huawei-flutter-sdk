import 'package:flutter/services.dart';

import 'channel_contract.dart';
import 'infobip_mobilemessaging_huawei_platform.dart';

final class MethodChannelInfobipMobileMessagingHuawei
    extends InfobipMobileMessagingHuaweiPlatform {
  MethodChannelInfobipMobileMessagingHuawei({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : methodChannel =
           methodChannel ?? const MethodChannel(ChannelContract.methodChannel),
       eventChannel =
           eventChannel ?? const EventChannel(ChannelContract.eventChannel) {
    _events = this.eventChannel.receiveBroadcastStream().asBroadcastStream();
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
}
