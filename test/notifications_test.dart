import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/channel_contract.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/infobip_mobilemessaging_huawei_platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class NotificationsPlatform extends InfobipMobileMessagingHuaweiPlatform
    with MockPlatformInterfaceMixin {
  final eventsController = StreamController<Object?>.broadcast();
  bool? registrationArgument;
  bool registrationEnabled = true;

  @override
  Stream<Object?> get events => eventsController.stream;

  @override
  Future<void> initialize({required String applicationCode}) async {}

  @override
  Future<bool> isRegistrationEnabled() async => registrationEnabled;

  @override
  Future<void> setRegistration({required bool enabled}) async {
    registrationArgument = enabled;
  }
}

Map<String, Object?> envelope(String type, Map<String, Object?> payload) => {
  'version': ChannelContract.eventVersion,
  'type': type,
  'timestamp': 1,
  'payload': payload,
};

void main() {
  late NotificationsPlatform platform;

  setUp(() {
    platform = NotificationsPlatform();
    InfobipMobileMessagingHuaweiPlatform.instance = platform;
  });

  tearDown(() => platform.eventsController.close());

  test('delegates registration operations', () async {
    await InfobipMobileMessagingHuawei.notifications.setRegistration(
      enabled: false,
    );
    expect(platform.registrationArgument, isFalse);
    expect(
      await InfobipMobileMessagingHuawei.notifications
          .isRegistrationEnabled(),
      isTrue,
    );
  });

  test('decodes message received events', () async {
    final future = InfobipMobileMessagingHuawei.notifications.onMessageReceived
        .first;
    platform.eventsController.add(
      envelope(ChannelContract.messageReceived, {
        'message': {
          'messageId': 'message-1',
          'title': 'Title',
          'body': 'Body',
          'customPayload': {'orderId': 42},
          'deepLink': 'app://orders/42',
          'isSilent': true,
        },
      }),
    );
    final message = await future;
    expect(message.messageId, 'message-1');
    expect(message.customPayload, {'orderId': 42});
    expect(message.isSilent, isTrue);
  });

  test('decodes action and registration events', () async {
    final actionFuture = InfobipMobileMessagingHuawei
        .notifications
        .onNotificationActionTapped
        .first;
    final registrationFuture = InfobipMobileMessagingHuawei
        .notifications
        .onRegistrationUpdated
        .first;
    platform.eventsController
      ..add(
        envelope(ChannelContract.notificationActionTapped, {
          'actionId': 'accept',
          'message': {'messageId': 'message-2', 'isSilent': false},
        }),
      )
      ..add(
        envelope(ChannelContract.registrationUpdated, {
          'isRegistrationEnabled': false,
        }),
      );
    expect((await actionFuture).actionId, 'accept');
    expect((await registrationFuture).isRegistrationEnabled, isFalse);
  });

  test('ignores malformed and unknown events without closing the stream', () async {
    final future = InfobipMobileMessagingHuawei.notifications.onMessageReceived
        .first;
    platform.eventsController
      ..add({'version': 1, 'type': 'future_event', 'payload': {}})
      ..add(envelope(ChannelContract.messageReceived, {'message': 'bad'}))
      ..add(
        envelope(ChannelContract.messageReceived, {
          'message': {'messageId': 'valid', 'isSilent': false},
        }),
      );
    expect((await future).messageId, 'valid');
  });
}
