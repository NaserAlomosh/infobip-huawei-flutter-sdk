import '../notifications/notifications.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';
import '../user/user.dart';
import '../installation/installation.dart';
import '../inbox/inbox.dart';
import '../chat/chat.dart';
import '../custom_event/custom_event.dart';

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

  /// Removes local Mobile Messaging SDK data and state.
  ///
  /// Initialize the SDK again before further use. For signing a user out, use
  /// [depersonalize] instead.
  static Future<void> cleanup() =>
      InfobipMobileMessagingHuaweiPlatform.instance.cleanup();

  /// Asks the Infobip SDK to register this installation for remote
  /// notifications.
  ///
  /// The host application must obtain Android notification permission first.
  static Future<void> registerForRemoteNotifications() =>
      InfobipMobileMessagingHuaweiPlatform.instance
          .registerForRemoteNotifications();

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

  /// Queues [event] for submission using the Huawei SDK.
  static Future<void> submitEvent(InfobipHuaweiCustomEvent event) =>
      InfobipMobileMessagingHuaweiPlatform.instance.submitEvent(event);

  /// Submits [event] and completes after the Huawei SDK callback succeeds.
  static Future<InfobipHuaweiCustomEvent> submitEventImmediately(
    InfobipHuaweiCustomEvent event,
  ) => InfobipMobileMessagingHuaweiPlatform.instance.submitEventImmediately(
    event,
  );

  /// Depersonalizes the installation identified by [pushRegistrationId].
  static Future<List<Installation>> depersonalizeInstallation(
    String pushRegistrationId,
  ) {
    final id = pushRegistrationId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        pushRegistrationId,
        'pushRegistrationId',
        'Must not be empty or whitespace-only',
      );
    }
    return InfobipMobileMessagingHuaweiPlatform.instance
        .depersonalizeInstallation(id);
  }

  /// Changes primary status for the installation identified by its push ID.
  static Future<List<Installation>> setInstallationAsPrimary({
    required String pushRegistrationId,
    required bool isPrimary,
  }) {
    final id = pushRegistrationId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        pushRegistrationId,
        'pushRegistrationId',
        'Must not be empty or whitespace-only',
      );
    }
    return InfobipMobileMessagingHuaweiPlatform.instance
        .setInstallationAsPrimary(
          pushRegistrationId: id,
          isPrimary: isPrimary,
        );
  }

  /// Configures the memory-only Infobip JWT used by native SDK requests.
  ///
  /// Passing `null` or a whitespace-only value clears the current JWT.
  static Future<void> setJwt(String? jwt) =>
      InfobipMobileMessagingHuaweiPlatform.instance.setJwt(
        jwt?.trim().isEmpty == true ? null : jwt?.trim(),
      );

  /// Returns the locally cached installation without network access.
  static Future<Installation> getInstallation() =>
      InfobipMobileMessagingHuaweiPlatform.instance.getInstallation();

  /// Refreshes and returns the installation from Infobip services.
  static Future<Installation> fetchInstallation() =>
      InfobipMobileMessagingHuaweiPlatform.instance.fetchInstallation();

  /// Saves writable installation properties and returns the resulting state.
  static Future<Installation> saveInstallation(Installation installation) =>
      InfobipMobileMessagingHuaweiPlatform.instance.saveInstallation(
        installation,
      );

  /// Fetches Inbox messages for [externalUserId].
  ///
  /// A non-empty [jwt] overrides the globally configured JWT. When [jwt] is
  /// absent or whitespace-only, the native SDK uses the global JWT, if set,
  /// and otherwise uses Application Code authorization.
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
    return InfobipMobileMessagingHuaweiPlatform.instance.fetchInbox(
      externalUserId: externalUserId,
      jwt: jwt?.trim().isEmpty == true ? null : jwt?.trim(),
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
    return InfobipMobileMessagingHuaweiPlatform.instance.setInboxMessagesSeen(
      externalUserId: externalUserId,
      messageIds: List.unmodifiable(messageIds),
    );
  }
}
