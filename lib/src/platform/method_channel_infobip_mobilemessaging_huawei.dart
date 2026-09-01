import 'package:flutter/services.dart';

import 'channel_contract.dart';
import 'infobip_mobilemessaging_huawei_platform.dart';

final class MethodChannelInfobipMobileMessagingHuawei
    extends InfobipMobileMessagingHuaweiPlatform {
  MethodChannelInfobipMobileMessagingHuawei({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : methodChannel = methodChannel ?? const MethodChannel(ChannelContract.methodChannel),
       eventChannel = eventChannel ?? const EventChannel(ChannelContract.eventChannel);

  final MethodChannel methodChannel;
  final EventChannel eventChannel;

  @override
  Stream<Object?> get events => eventChannel.receiveBroadcastStream();
}
