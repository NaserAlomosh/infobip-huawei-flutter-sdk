import 'dart:async';

import '../platform/channel_contract.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';
import 'notification_events.dart';
import 'push_message.dart';

/// Notification and registration lifecycle events.
final class InfobipHuaweiNotifications {
  InfobipHuaweiNotifications._();

  static final InfobipHuaweiNotifications instance =
      InfobipHuaweiNotifications._();

  Stream<Object?> get _events =>
      InfobipMobileMessagingHuaweiPlatform.instance.events;

  Stream<PushMessage> get onMessageReceived =>
      _typed(ChannelContract.messageReceived, _message);

  Stream<PushMessage> get onNotificationTapped =>
      _typed(ChannelContract.notificationTapped, _message);

  Stream<NotificationActionEvent> get onNotificationActionTapped => _typed(
    ChannelContract.notificationActionTapped,
    (payload) => NotificationActionEvent(
      actionId: payload['actionId'] as String?,
      message: _message(payload),
    ),
  );

  Stream<RegistrationUpdatedEvent> get onRegistrationUpdated => _typed(
    ChannelContract.registrationUpdated,
    (payload) => RegistrationUpdatedEvent(
      isRegistrationEnabled: payload['isRegistrationEnabled'] as bool,
    ),
  );

  Stream<T> _typed<T>(
    String type,
    T Function(Map<Object?, Object?> payload) decode,
  ) => _events.transform(
    StreamTransformer<Object?, T>.fromHandlers(
      handleData: (event, sink) {
        if (event is! Map ||
            event['version'] != ChannelContract.eventVersion ||
            event['type'] != type ||
            event['payload'] is! Map) {
          return;
        }
        try {
          sink.add(decode(event['payload'] as Map<Object?, Object?>));
        } on Object {
          // Malformed native events are ignored without terminating subscriptions.
        }
      },
    ),
  );

  static PushMessage _message(Map<Object?, Object?> payload) {
    final message = payload['message'];
    if (message is! Map) throw const FormatException('Missing message');
    return PushMessage.fromMap(message.cast<Object?, Object?>());
  }
}
