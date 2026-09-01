import 'inbox.dart';
import '../platform/channel_contract.dart';

abstract final class InboxCodec {
  static Map<String, Object?>? encodeOptions(InboxFilterOptions? options) {
    if (options == null) return null;
    if (options.from != null &&
        options.to != null &&
        options.from!.isAfter(options.to!)) {
      throw ArgumentError('from must not be after to');
    }
    if (options.topic != null && options.topic!.trim().isEmpty) {
      throw ArgumentError.value(options.topic, 'topic', 'Must not be empty');
    }
    if (options.topic != null && options.topics != null) {
      throw ArgumentError('topic and topics are mutually exclusive');
    }
    if (options.topics != null &&
        (options.topics!.isEmpty ||
            options.topics!.any((topic) => topic.trim().isEmpty))) {
      throw ArgumentError.value(
        options.topics,
        'topics',
        'Must contain non-empty values',
      );
    }
    if (options.limit != null && options.limit! <= 0) {
      throw ArgumentError.value(options.limit, 'limit', 'Must be positive');
    }
    return {
      ChannelContract.from: options.from?.toUtc().toIso8601String(),
      ChannelContract.to: options.to?.toUtc().toIso8601String(),
      ChannelContract.topic: options.topic,
      ChannelContract.topics: options.topics,
      ChannelContract.limit: options.limit,
    };
  }

  static Inbox decode(Object? value) {
    final map = _map(value, 'Inbox result');
    final messages = map[ChannelContract.messages];
    if (messages is! List) throw const FormatException('Invalid Inbox messages');
    return Inbox(
      countTotal: _integer(map[ChannelContract.countTotal], 'countTotal'),
      countUnread: _integer(map[ChannelContract.countUnread], 'countUnread'),
      countTotalFiltered: _integer(
        map[ChannelContract.countTotalFiltered],
        'countTotalFiltered',
      ),
      countUnreadFiltered: _integer(
        map[ChannelContract.countUnreadFiltered],
        'countUnreadFiltered',
      ),
      messages: List.unmodifiable(messages.map(_decodeMessage)),
    );
  }

  static InboxMessage _decodeMessage(Object? value) {
    final map = _map(value, 'Inbox message');
    final id = map[ChannelContract.messageId];
    final seen = map[ChannelContract.seen];
    if (id is! String || id.isEmpty || seen is! bool) {
      throw const FormatException('Invalid Inbox message');
    }
    return InboxMessage(
      messageId: id,
      title: _nullableString(map[ChannelContract.title], 'title'),
      body: _nullableString(map[ChannelContract.body], 'body'),
      topic: _nullableString(map[ChannelContract.topic], 'topic'),
      seen: seen,
      receivedTimestamp: _date(map[ChannelContract.receivedTimestamp]),
      customPayload: _payload(map[ChannelContract.customPayload]),
      deepLink: _nullableString(map[ChannelContract.deepLink], 'deepLink'),
      isSilent: map[ChannelContract.isSilent] as bool? ?? false,
    );
  }

  static Map<Object?, Object?> _map(Object? value, String name) {
    if (value is! Map) throw FormatException('$name must be a map');
    return value;
  }

  static int _integer(Object? value, String name) {
    if (value is! int || value < 0) throw FormatException('Invalid $name');
    return value;
  }

  static String? _nullableString(Object? value, String name) {
    if (value == null) return null;
    if (value is! String) throw FormatException('Invalid $name');
    return value;
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Invalid Inbox timestamp');
    return DateTime.tryParse(value)?.toUtc() ??
        (throw const FormatException('Invalid Inbox timestamp'));
  }

  static Map<String, Object?> _payload(Object? value) {
    if (value == null) return const {};
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid Inbox custom payload');
    }
    return Map.unmodifiable(
      value.map((key, item) => MapEntry(key as String, _payloadValue(item))),
    );
  }

  static Object? _payloadValue(Object? value) => switch (value) {
    null || String() || bool() || int() || double() => value,
    List() => List.unmodifiable(value.map(_payloadValue)),
    Map() when value.keys.every((key) => key is String) => Map.unmodifiable(
      value.map((key, item) => MapEntry(key as String, _payloadValue(item))),
    ),
    _ => throw const FormatException('Invalid Inbox custom payload'),
  };
}
