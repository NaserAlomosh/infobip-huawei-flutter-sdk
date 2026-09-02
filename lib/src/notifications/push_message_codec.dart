import 'push_message.dart';

abstract final class PushMessageCodec {
  static PushMessage decode(Map<Object?, Object?> map) => PushMessage(
    messageId: _nullableString(map['messageId'], 'messageId'),
    title: _nullableString(map['title'], 'title'),
    body: _nullableString(map['body'], 'body'),
    customPayload: _stringObjectMap(map['customPayload']),
    deepLink: _nullableString(map['deepLink'], 'deepLink'),
    isSilent: _requiredBool(map['isSilent'], 'isSilent'),
  );

  static Map<String, Object?> _stringObjectMap(Object? value) {
    if (value == null) return const {};
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('customPayload must be a string-keyed map');
    }
    return Map.unmodifiable(
      value.map(
        (key, item) => MapEntry(key as String, _payloadValue(item)),
      ),
    );
  }

  static String? _nullableString(Object? value, String name) {
    if (value == null || value is String) return value as String?;
    throw FormatException('$name must be a string');
  }

  static bool _requiredBool(Object? value, String name) {
    if (value is bool) return value;
    throw FormatException('$name must be a boolean');
  }

  static Object? _payloadValue(Object? value) => switch (value) {
    null || String() || bool() || int() || double() => value,
    List() => List.unmodifiable(value.map(_payloadValue)),
    Map() when value.keys.every((key) => key is String) => Map.unmodifiable(
      value.map((key, item) => MapEntry(key as String, _payloadValue(item))),
    ),
    _ => throw const FormatException('customPayload contains an invalid value'),
  };
}
