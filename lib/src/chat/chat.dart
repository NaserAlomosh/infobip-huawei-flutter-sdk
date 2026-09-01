import 'dart:async';

import '../platform/channel_contract.dart';
import '../platform/infobip_mobilemessaging_huawei_platform.dart';

/// Global APIs for the Infobip Chat session.
final class InfobipHuaweiChat {
  InfobipHuaweiChat._();

  static final InfobipHuaweiChat instance = InfobipHuaweiChat._();

  /// Returns the current number of unread Chat messages.
  Future<int> getUnreadMessageCount() => InfobipMobileMessagingHuaweiPlatform
      .instance
      .getChatUnreadMessageCount();

  /// Emits future native unread-counter updates without replaying a value.
  Stream<int> get onUnreadMessageCounterUpdated =>
      InfobipMobileMessagingHuaweiPlatform.instance.events.transform(
        StreamTransformer<Object?, int>.fromHandlers(
          handleData: (event, sink) {
            if (event is! Map ||
                event['version'] != ChannelContract.eventVersion ||
                event['type'] !=
                    ChannelContract.chatUnreadMessageCounterUpdated ||
                event['payload'] is! Map) {
              return;
            }
            final count = (event['payload'] as Map)['count'];
            if (count is int && count >= 0) sink.add(count);
          },
        ),
      );
}
