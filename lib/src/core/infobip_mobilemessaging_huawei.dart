import '../notifications/notifications.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';

/// Entry point for the Infobip Huawei Mobile Messaging plugin.
final class InfobipMobileMessagingHuawei {
  InfobipMobileMessagingHuawei._();

  /// Notification and registration lifecycle events.
  static InfobipHuaweiNotifications get notifications =>
      InfobipHuaweiNotifications.instance;

  /// Initializes the native SDK with an Infobip application code.
  ///
  /// Equivalent calls are idempotent. A different application code is rejected
  /// once initialization has started.
  static Future<void> initialize({required String applicationCode}) {
    if (applicationCode.trim().isEmpty) {
      throw ArgumentError.value(
        applicationCode,
        'applicationCode',
        'Must not be empty or whitespace-only',
      );
    }
    return InfobipMobileMessagingHuaweiPlatform.instance.initialize(
      applicationCode: applicationCode,
    );
  }
}
