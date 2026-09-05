import 'package:flutter/services.dart';

import '../platform/channel_contract.dart';
import '../user/user_codec.dart';
import 'custom_event.dart';

abstract final class CustomEventCodec {
  static Map<String, Object?> encode(InfobipHuaweiCustomEvent event) {
    final definitionId = event.definitionId.trim();
    if (definitionId.isEmpty) {
      throw ArgumentError.value(
        event.definitionId,
        'event.definitionId',
        'Must not be empty or whitespace-only',
      );
    }
    if (event.eventId != null || event.createdAt != null) {
      throw const PlatformException(
        code: 'invalid_argument',
        message: 'eventId and createdAt are read-only',
      );
    }
    return <String, Object?>{
      ChannelContract.definitionId: definitionId,
      ChannelContract.properties: UserCodec.encodeCustomAttributes(
        event.properties,
      ),
    };
  }

  static InfobipHuaweiCustomEvent decode(Object? value) {
    if (value is! Map) {
      throw const FormatException('Custom event payload must be a map.');
    }
    final map = value.cast<Object?, Object?>();
    final definitionId = map[ChannelContract.definitionId];
    final eventId = map[ChannelContract.eventId];
    final createdAt = map[ChannelContract.createdAt];
    if (definitionId is! String || definitionId.trim().isEmpty) {
      throw const FormatException('definitionId must be a non-empty string.');
    }
    if (eventId != null && eventId is! String) {
      throw const FormatException('eventId must be a string.');
    }
    if (createdAt != null && createdAt is! String) {
      throw const FormatException('createdAt must be a string.');
    }
    final parsedCreatedAt = createdAt == null
        ? null
        : DateTime.tryParse(createdAt);
    if (createdAt != null && parsedCreatedAt == null) {
      throw const FormatException('createdAt must be an ISO-8601 timestamp.');
    }
    return InfobipHuaweiCustomEvent(
      definitionId: definitionId,
      eventId: eventId as String?,
      createdAt: parsedCreatedAt?.toUtc(),
      properties: UserCodec.decodeCustomAttributes(
        map[ChannelContract.properties],
      ),
    );
  }
}
