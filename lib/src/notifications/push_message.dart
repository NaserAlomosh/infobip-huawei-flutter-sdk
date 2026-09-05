/// An immutable, channel-safe projection of an Infobip push message.
final class PushMessage {
  const PushMessage({
    required this.messageId,
    required this.title,
    required this.body,
    required this.customPayload,
    required this.deepLink,
    required this.isSilent,
  });

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, Object?> customPayload;
  final String? deepLink;
  final bool isSilent;
}
