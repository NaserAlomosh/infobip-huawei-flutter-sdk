import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';
import 'package:infobip_mobilemessaging_huawei/src/inbox/inbox_codec.dart';
import 'package:infobip_mobilemessaging_huawei/src/platform/channel_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodes filters as UTC instants and preserves absent filters', () {
    expect(InboxCodec.encodeOptions(null), isNull);
    final encoded = InboxCodec.encodeOptions(
      InboxFilterOptions(
        from: DateTime.parse('2026-09-01T15:00:00+03:00'),
        to: DateTime.parse('2026-09-02T12:00:00Z'),
        topic: 'offers',
        limit: 20,
      ),
    );
    expect(encoded, {
      'from': '2026-09-01T12:00:00.000Z',
      'to': '2026-09-02T12:00:00.000Z',
      'topic': 'offers',
      'limit': 20,
    });
  });

  test('rejects invalid filters', () {
    expect(
      () => InboxCodec.encodeOptions(
        InboxFilterOptions(
          from: DateTime.utc(2026, 2),
          to: DateTime.utc(2026, 1),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => InboxCodec.encodeOptions(const InboxFilterOptions(topic: ' ')),
      throwsArgumentError,
    );
    expect(
      () => InboxCodec.encodeOptions(const InboxFilterOptions(limit: 0)),
      throwsArgumentError,
    );
  });

  test('decodes Inbox counters, messages, timestamp, and nested payload', () {
    final inbox = InboxCodec.decode({
      'countTotal': 4,
      'countUnread': 2,
      'messages': [
        {
          'messageId': 'message-1',
          'title': 'Title',
          'body': 'Body',
          'topic': 'news',
          'seen': false,
          'receivedTimestamp': '2026-09-01T12:00:00Z',
          'customPayload': {
            'nested': {'enabled': true},
          },
          'deepLink': 'app://inbox',
          'isSilent': true,
        },
      ],
    });
    expect(inbox.countTotal, 4);
    expect(inbox.countUnread, 2);
    expect(inbox.messages.single.messageId, 'message-1');
    expect(inbox.messages.single.receivedTimestamp, DateTime.utc(2026, 9, 1, 12));
    expect(inbox.messages.single.customPayload['nested'], {'enabled': true});
    expect(inbox.messages.single.seen, isFalse);
    expect(inbox.messages.single.isSilent, isTrue);
  });

  test('rejects malformed native Inbox results', () {
    expect(() => InboxCodec.decode(null), throwsFormatException);
    expect(
      () => InboxCodec.decode({
        'countTotal': 1,
        'countUnread': 0,
        'messages': const ['bad'],
      }),
      throwsFormatException,
    );
  });

  test('delegates fetch and seen operations over the channel', () async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel(ChannelContract.methodChannel),
      (call) async {
        calls.add(call);
        if (call.method == ChannelContract.fetchInbox) {
          return {'countTotal': 0, 'countUnread': 0, 'messages': <Object?>[]};
        }
        return null;
      },
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel(ChannelContract.methodChannel),
        null,
      ),
    );

    final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
      const InboxFilterOptions(topic: 'news', limit: 10),
    );
    await InfobipMobileMessagingHuawei.setInboxMessagesSeen(['one', 'two']);

    expect(inbox.messages, isEmpty);
    expect(calls.map((call) => call.method), [
      ChannelContract.fetchInbox,
      ChannelContract.setInboxMessagesSeen,
    ]);
    expect(calls.last.arguments, {
      ChannelContract.messageIds: ['one', 'two'],
    });
  });

  test('rejects an empty seen update without invoking native code', () {
    expect(
      () => InfobipMobileMessagingHuawei.setInboxMessagesSeen(const []),
      throwsArgumentError,
    );
  });
}
