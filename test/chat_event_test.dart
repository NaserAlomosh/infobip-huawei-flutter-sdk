import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/src/chat/chat_event.dart';
import 'package:infobip_mobilemessaging_huawei/src/chat/chat_view.dart';

void main() {
  test('decodes loaded event', () {
    expect(
      decodeInfobipHuaweiChatEvent(<String, Object>{'event': 'loaded'}),
      isA<InfobipHuaweiChatLoadedEvent>(),
    );
  });

  test('decodes every known view state and preserves order', () {
    const values = <String>[
      'LOADING',
      'THREAD_LIST',
      'LOADING_THREAD',
      'THREAD',
      'CLOSED_THREAD',
      'SINGLE_MODE_THREAD',
    ];

    final events = values
        .map(
          (value) => decodeInfobipHuaweiChatEvent(<String, Object>{
            'event': 'viewChanged',
            'value': value,
          }),
        )
        .whereType<InfobipHuaweiChatViewChangedEvent>()
        .toList();

    expect(events.map((event) => event.rawValue), values);
    expect(
      events.map((event) => event.state),
      InfobipHuaweiChatViewState.values.where(
        (state) => state != InfobipHuaweiChatViewState.unknown,
      ),
    );
  });

  test('decodes connection changes', () {
    final connected = decodeInfobipHuaweiChatEvent(<String, Object>{
      'event': 'connectionChanged',
      'value': 'CONNECTED',
    }) as InfobipHuaweiChatConnectionChangedEvent;
    final disconnected = decodeInfobipHuaweiChatEvent(<String, Object>{
      'event': 'connectionChanged',
      'value': 'DISCONNECTED',
    }) as InfobipHuaweiChatConnectionChangedEvent;

    expect(connected.state, InfobipHuaweiChatConnectionState.connected);
    expect(disconnected.state, InfobipHuaweiChatConnectionState.disconnected);
  });

  test('preserves unknown values without throwing', () {
    final event = decodeInfobipHuaweiChatEvent(<String, Object>{
      'event': 'viewChanged',
      'value': 'FUTURE_VIEW',
    }) as InfobipHuaweiChatViewChangedEvent;

    expect(event.state, InfobipHuaweiChatViewState.unknown);
    expect(event.rawValue, 'FUTURE_VIEW');
  });

  test('ignores malformed, unrelated, and JWT events', () {
    expect(decodeInfobipHuaweiChatEvent(null), isNull);
    expect(
      decodeInfobipHuaweiChatEvent(<String, Object>{
        'event': 'viewChanged',
        'value': 1,
      }),
      isNull,
    );
    expect(
      decodeInfobipHuaweiChatEvent(<String, Object>{
        'event': 'chat_jwt_requested',
      }),
      isNull,
    );
  });
}
