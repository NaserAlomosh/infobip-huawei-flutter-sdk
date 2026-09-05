/// Server-side options used when fetching Inbox messages.
final class InboxFilterOptions {
  const InboxFilterOptions({
    this.from,
    this.to,
    this.topic,
    this.topics,
    this.limit,
  });

  /// Lower bound for message creation time, forwarded as a UTC instant.
  final DateTime? from;

  /// Upper bound for message creation time, forwarded as a UTC instant.
  final DateTime? to;

  /// Exact Inbox topic to request.
  final String? topic;

  /// Exact Inbox topics to request.
  ///
  /// This cannot be combined with [topic].
  final List<String>? topics;

  /// Maximum number of messages returned by the server.
  final int? limit;
}

/// A page of Inbox messages and server-authoritative counters.
final class Inbox {
  const Inbox({
    required this.countTotal,
    required this.countUnread,
    required this.countTotalFiltered,
    required this.countUnreadFiltered,
    required this.messages,
  });

  final int countTotal;
  final int countUnread;
  final int countTotalFiltered;
  final int countUnreadFiltered;
  final List<InboxMessage> messages;
}

/// A message returned by Infobip Inbox.
final class InboxMessage {
  const InboxMessage({
    required this.messageId,
    required this.title,
    required this.body,
    required this.topic,
    required this.seen,
    required this.receivedTimestamp,
    required this.customPayload,
    required this.deepLink,
    required this.isSilent,
  });

  final String messageId;
  final String? title;
  final String? body;
  final String? topic;
  final bool seen;
  final DateTime? receivedTimestamp;
  final Map<String, Object?> customPayload;
  final String? deepLink;
  final bool isSilent;
}
