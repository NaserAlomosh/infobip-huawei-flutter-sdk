import '../notifications/notifications.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';
import '../user/user.dart';
import '../installation/installation.dart';
import '../inbox/inbox.dart';
import '../chat/chat.dart';

/// Entry point for the Infobip Huawei Mobile Messaging plugin.
final class InfobipMobileMessagingHuawei {
  InfobipMobileMessagingHuawei._();

  /// Notification and registration lifecycle events.
  static InfobipHuaweiNotifications get notifications =>
      InfobipHuaweiNotifications.instance;

  /// Global Chat state and events.
  static InfobipHuaweiChat get chat => InfobipHuaweiChat.instance;

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

  /// Fetches Inbox messages for [externalUserId].
  ///
  /// When supplied, [jwt] is forwarded only for this request and is not stored.
  static Future<Inbox> fetchInbox({
    required String externalUserId,
    String? jwt,
    InboxFilterOptions? options,
  }) {
    if (externalUserId.trim().isEmpty) {
      throw ArgumentError.value(
        externalUserId,
        'externalUserId',
        'Must not be empty or whitespace-only',
      );
    }
    if (jwt != null && jwt.trim().isEmpty) {
      throw ArgumentError.value(
        jwt,
        'jwt',
        'Must not be empty or whitespace-only',
      );
    }
    return InfobipMobileMessagingHuaweiPlatform.instance.fetchInbox(
      externalUserId: externalUserId,
      jwt: jwt,
      options: options,
    );
  }

  /// Marks the Inbox messages identified by [messageIds] as seen.
  static Future<void> setInboxMessagesSeen({
    required String externalUserId,
    required List<String> messageIds,
  }) {
    if (externalUserId.trim().isEmpty) {
      throw ArgumentError.value(
        externalUserId,
        'externalUserId',
        'Must not be empty or whitespace-only',
      );
    }
    if (messageIds.isEmpty || messageIds.any((id) => id.trim().isEmpty)) {
      throw ArgumentError.value(messageIds, 'messageIds', 'Must not be empty');
    }
    return InfobipMobileMessagingHuaweiPlatform.instance
        .setInboxMessagesSeen(
          externalUserId: externalUserId,
          messageIds: List.unmodifiable(messageIds),
        );
  }
}
