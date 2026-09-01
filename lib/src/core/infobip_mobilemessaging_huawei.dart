import '../notifications/notifications.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';
import '../user/user.dart';
import '../installation/installation.dart';

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

  /// Returns the locally cached user without making a server request.
  static Future<User> getUser() =>
      InfobipMobileMessagingHuaweiPlatform.instance.getUser();

  /// Refreshes and returns the user from Infobip services.
  static Future<User> fetchUser() =>
      InfobipMobileMessagingHuaweiPlatform.instance.fetchUser();

  /// Saves the supplied profile and completes with the resulting user.
  static Future<User> saveUser(User user) =>
      InfobipMobileMessagingHuaweiPlatform.instance.saveUser(user);

  /// Associates this installation with [userIdentity] and optional attributes.
  static Future<User> personalize(
    UserIdentity userIdentity, [
    UserAttributes? userAttributes,
    bool forceDepersonalize = false,
  ]) => InfobipMobileMessagingHuaweiPlatform.instance.personalize(
    userIdentity,
    userAttributes,
    forceDepersonalize: forceDepersonalize,
  );

  /// Removes the current personalization on the Infobip service.
  static Future<void> depersonalize() =>
      InfobipMobileMessagingHuaweiPlatform.instance.depersonalize();

  /// Returns the locally cached installation without network access.
  static Future<Installation> getInstallation() =>
      InfobipMobileMessagingHuaweiPlatform.instance.getInstallation();

  /// Refreshes and returns the installation from Infobip services.
  static Future<Installation> fetchInstallation() =>
      InfobipMobileMessagingHuaweiPlatform.instance.fetchInstallation();

  /// Saves writable installation properties and returns the resulting state.
  static Future<Installation> saveInstallation(Installation installation) =>
      InfobipMobileMessagingHuaweiPlatform.instance.saveInstallation(installation);
}
