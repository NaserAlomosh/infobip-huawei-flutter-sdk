/// A Mobile Messaging notification payload.
///
/// [originalPayload] is an iOS-only value in the official Flutter plugin and
/// is always `null` on Huawei Android.
final class Message {
  const Message({
    this.messageId,
    this.title,
    this.body,
    this.sound,
    this.vibrate,
    this.icon,
    bool? silent,
    this.category,
    this.customPayload,
    this.internalData,
    this.receivedTimestamp,
    this.seenDate,
    this.contentUrl,
    this.seen,
    this.originalPayload,
    this.browserUrl,
    String? deeplink,
    this.webViewUrl,
    this.inAppOpenTitle,
    this.inAppDismissTitle,
    this.chat,
    this.topic,
    String? deepLink,
    bool? isSilent,
  })  : silent = silent ?? isSilent,
        deeplink = deeplink ?? deepLink;

  final String? messageId;
  final String? title;
  final String? body;
  final String? sound;
  final bool? vibrate;
  final String? icon;
  final bool? silent;
  final String? category;
  final Map<String, Object?>? customPayload;
  final String? internalData;
  final DateTime? receivedTimestamp;
  final DateTime? seenDate;
  final String? contentUrl;
  final bool? seen;
  final Map<String, Object?>? originalPayload;
  final String? browserUrl;
  final String? deeplink;
  final String? webViewUrl;
  final String? inAppOpenTitle;
  final String? inAppDismissTitle;
  final bool? chat;

  /// Huawei Mobile Inbox topic. This is not populated for push events.
  final String? topic;

  @Deprecated('Use deeplink')
  String? get deepLink => deeplink;

  @Deprecated('Use silent')
  bool get isSilent => silent ?? false;
}
