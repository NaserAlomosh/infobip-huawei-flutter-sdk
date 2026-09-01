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

  factory PushMessage.fromMap(Map<Object?, Object?> map) {
    return PushMessage(
      messageId: map['messageId'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      customPayload: _stringObjectMap(map['customPayload']),
      deepLink: map['deepLink'] as String?,
      isSilent: map['isSilent'] as bool? ?? false,
    );
  }

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, Object?> customPayload;
  final String? deepLink;
  final bool isSilent;

  static Map<String, Object?> _stringObjectMap(Object? value) {
    if (value is! Map) return const {};
    return Map.unmodifiable(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
