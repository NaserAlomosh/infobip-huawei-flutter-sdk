import 'package:flutter_test/flutter_test.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';
import 'package:infobip_mobilemessaging_huawei/src/installation/installation_codec.dart';
import 'package:infobip_mobilemessaging_huawei/src/notifications/push_message_codec.dart';
import 'package:infobip_mobilemessaging_huawei/src/user/user_codec.dart';

void main() {
  test('maps the complete Huawei message contract', () {
    final message = PushMessageCodec.decode({
      'messageId': 'm1', 'title': 'Title', 'body': 'Body', 'sound': 'default',
      'vibrate': true, 'icon': 'push', 'silent': false, 'category': 'offer',
      'customPayload': {'id': 7}, 'receivedTimestamp': 1788264000000,
      'seenDate': '2026-09-01T12:01:00Z', 'seen': true,
      'contentUrl': 'https://example.test/content',
      'browserUrl': 'https://example.test', 'deeplink': 'app://offer',
      'webViewUrl': 'https://example.test/web', 'inAppOpenTitle': 'Open',
      'inAppDismissTitle': 'Dismiss', 'chat': false,
    });
    expect(message.messageId, 'm1');
    expect(message.sound, 'default');
    expect(message.vibrate, isTrue);
    expect(message.receivedTimestamp, isNotNull);
    expect(message.seenDate, DateTime.utc(2026, 9, 1, 12, 1));
    expect(message.seen, isTrue);
    expect(message.deeplink, 'app://offer');
    expect(message.originalPayload, isNull);
    expect(message.internalData, isNull);
    expect(message.chat, isFalse);
  });

  test('maps installation official names, HMS, and writable fields', () {
    final installation = InstallationCodec.decode({
      'pushRegistrationId': 'registration', 'pushServiceToken': 'token',
      'pushServiceType': 'HMS', 'isPrimaryDevice': false,
      'isPushRegistrationEnabled': true, 'notificationsEnabled': true,
      'sdkVersion': '8.14.0', 'appVersion': '1.0', 'os': 'Android',
      'osVersion': '16', 'deviceManufacturer': 'Huawei',
      'deviceModel': 'device', 'deviceSecure': true, 'language': 'en',
      'deviceTimezoneOffset': '+00:00', 'applicationUserId': 'user',
      'deviceName': 'phone', 'customAttributes': {'tier': 'gold'},
    });
    expect(installation.pushServiceType, PushServiceType.HMS);
    expect(installation.isPushRegistrationEnabled, isTrue);
    expect(installation.appVersion, '1.0');
    installation
      ..isPrimaryDevice = true
      ..isPushRegistrationEnabled = false;
    final writable = InstallationCodec.encodeWritable(installation);
    expect(writable.keys, containsAll(['isPrimaryDevice', 'isPushRegistrationEnabled', 'customAttributes']));
    expect(writable, isNot(contains('notificationsEnabled')));
    expect(installation.pushRegistrationEnabled, isFalse);
  });

  test('maps UserData type and nested installations', () {
    final user = UserCodec.decode({
      'externalUserId': 'user', 'gender': 'female', 'type': 'customer',
      'installations': [
        {'pushServiceType': 'HMS', 'isPrimaryDevice': true},
      ],
    });
    expect(user, isA<UserData>());
    expect(user.gender, Gender.Female);
    expect(user.type, Type.Customer);
    expect(user.installations?.single.pushServiceType, PushServiceType.HMS);
  });

  test('constructs official personalization and filter models', () {
    const context = PersonalizeContext(
      forceDepersonalize: true,
      userIdentity: UserIdentity(externalUserId: 'user'),
      userAttributes: UserAttributes(firstName: 'Sam'),
    );
    expect(context.forceDepersonalize, isTrue);
    final from = DateTime.utc(2026, 9, 1);
    final options = FilterOptions(fromDateTime: from, topic: 'news', limit: 10);
    expect(options.fromDateTime, from);
    expect(options.from, from);
  });
}
