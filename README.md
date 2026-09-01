# Infobip Mobile Messaging Huawei for Flutter

An Android-only Flutter plugin being developed as a Flutter-facing wrapper for the official Infobip Huawei Mobile Messaging SDK.

> **Phase 8 status:** Core initialization, notifications, User Management, Installation Management, Inbox, and embedded Chat are implemented.

## Requirements

| Component | Version |
| --- | --- |
| Flutter | 3.35.7 or later within the current compatible SDK range |
| Android compile SDK | 36 |
| Android target SDK (host example) | 36 |
| Android minimum SDK | 26 |
| Java | 17 |
| Kotlin JVM target | 17 |
| Kotlin Gradle Plugin | 2.1.0 |
| Android Gradle Plugin | 8.13.0 |
| Gradle | 8.13 |
| Infobip Huawei SDK | 8.14.0 |

Only Android is registered in the package manifest. There is no iOS implementation.

## Architecture

```text
Public Dart API
    -> platform interface
        -> MethodChannel / EventChannel implementation
            -> Kotlin FlutterPlugin
                -> Infobip Huawei SDK 8.14.0
```

Channel names, method identifiers, and versioned event identifiers are centralized on both platforms. Initialization uses the method channel; unsolicited notification events use one shared event-channel subscription.

## Embedded Chat

Chat uses Huawei SDK 8.14.0's `InAppChatView` through a dedicated Android PlatformView. `InAppChatView` has no native toolbar, so Flutter retains ownership of the route, `AppBar`, and business actions without displaying a duplicate toolbar. The Infobip view retains its native composer, attachment workflow, focus handling, validation, and upload lifecycle.

Initialize the core SDK successfully before constructing Chat, then place the widget in any bounded Flutter layout:

```dart
final chatController = InfobipHuaweiChatController();

Scaffold(
  appBar: AppBar(title: const Text('Chat'), actions: [businessAction]),
  body: InfobipHuaweiChatView(controller: chatController),
);
```

For Flutter-owned back navigation, call `navigateBackOrCloseChat()` first and pop the Flutter route only when it returns `false`. A controller is bound to one PlatformView ID, is detached when its widget is disposed, and never targets a global or previously disposed Chat view. Each view uses the SDK-managed Chat singleton; the plugin does not create another `MobileMessaging` instance.

Creation without completed initialization renders the deterministic `not_initialized` state; creation while no Activity is attached renders `activity_unavailable`. Native operation failures use `chat_unavailable` and do not include messages, URLs, thread data, attachment paths, tokens, or stack traces.

Phase 8 intentionally does not expose full-screen Chat, availability, unread counts/events, raw-message or internal UI events, threads, programmatic sends, contextual data, language, or runtime theme commands. Although several are available in the Huawei component, the inspected official Flutter contract does not justify expanding the public API without stable portable models. Native attachments remain available from the native composer; Android resource theme configuration remains host-native configuration.

Android PlatformViews require real-device validation for IME resizing, accessibility, attachment permissions, Activity recreation, and route leave/re-entry behavior. No manual keyboard workaround is installed. Chat also requires a correctly configured Infobip application/backend and a Huawei device or suitable HMS environment. Never log Chat content, contextual data, URLs, identity, tokens, or local attachment paths.

## Initialization

Provide the Application Code issued for your Infobip application:

```dart
await InfobipMobileMessagingHuawei.initialize(
  applicationCode: 'APPLICATION_CODE',
);
```

The application code must be non-empty. Initialization is asynchronous and uses Android's application context. Concurrent calls with the same code share one native build, and after success later equivalent calls complete without rebuilding. Calls with a different code are rejected with `already_initialized`, including after a failed attempt. A failed initialization can be retried by calling `initialize` again with the same application code; the retry starts a new native build. Failures cross the channel as `PlatformException` with stable codes: `invalid_argument`, `already_initialized`, `initialization_failed`, or `native_error`.

## Push lifecycle and notification events

The Infobip Huawei SDK owns push registration and HMS Push Kit token acquisition and refresh as part of its native lifecycle. The primary Dart API does not expose registration enable/disable methods, a synchronous registration-state query, raw HMS token access, or token injection.

Registration state is available as `Installation.pushRegistrationEnabled`; Huawei-specific registration controls remain intentionally private.

The following typed streams wrap the SDK 8.14.0 `MESSAGE_RECEIVED`, `NOTIFICATION_TAPPED`, `ACTION_TAPPED`, and `REGISTRATION_UPDATED` events:

```dart
InfobipMobileMessagingHuawei.notifications.onMessageReceived;
InfobipMobileMessagingHuawei.notifications.onNotificationTapped;
InfobipMobileMessagingHuawei.notifications.onNotificationActionTapped;
InfobipMobileMessagingHuawei.notifications.onRegistrationUpdated;
InfobipMobileMessagingHuawei.notifications.onInstallationUpdated;
```

Messages contain only message ID, title, body, channel-safe custom payload, deep link, and silent status. Registration and installation updates carry a typed `Installation`. They are not retained for cold-start replay.

Native listeners are installed once per Flutter engine and removed on detach. Flutter sink delivery is marshalled to Android's main thread. The most recent notification tap is retained when Dart is not listening, replaces any earlier pending tap, is replayed once on listen, and is then cleared. Other events are not buffered.

There is no background Dart isolate. The native SDK can continue its own processing and notification display while Flutter is stopped, but no Dart callback executes while the application is terminated.

Android notification permission and Infobip registration are separate concerns. The official plugin's `registerForAndroidRemoteNotifications()` relates to Android remote-notification/permission behavior; it is not equivalent to native `MobileMessaging.setRegistration(...)`. This plugin does not currently expose a notification-permission API, and the host owns the permission declaration, rationale, and request UX.

## User management

All user calls require a successfully initialized SDK and otherwise fail with
`not_initialized`. The public API mirrors the official plugin's user workflow:

```dart
final cached = await InfobipMobileMessagingHuawei.getUser();
final refreshed = await InfobipMobileMessagingHuawei.fetchUser();
await InfobipMobileMessagingHuawei.saveUser(refreshed);

await InfobipMobileMessagingHuawei.personalize(
  const UserIdentity(externalUserId: 'sample-user-id'),
  const UserAttributes(firstName: 'Sample'),
);
await InfobipMobileMessagingHuawei.depersonalize();
```

`getUser()` returns the Huawei SDK's local snapshot. `fetchUser()` waits for its asynchronous
server refresh. Save, personalize, and depersonalize likewise complete only after the native SDK
callback. Personalization keeps identity (`externalUserId`, `phones`, and `emails`) separate from
profile attributes and supports the SDK's `forceDepersonalize` option.

`User` exposes external user ID, first/middle/last name, gender, birthday, phones, emails, tags,
and custom attributes. Gender uses stable `male` and `female` channel values. A null gender means
that the profile has no gender, while an unrecognized future native string decodes as
`Gender.unknown`. Because Huawei 8.14.0 accepts only its defined gender enum, `Gender.unknown` is
read-only: attempting to save it fails with `invalid_argument` instead of overwriting profile data.

Birthdays retain date-only `YYYY-MM-DD` semantics and do not carry a time or time zone. Huawei
8.14.0 custom attributes support strings, booleans, numbers, native dates, and lists containing
those values. Dart `DateTime` values are transmitted as native `Date` values and round-trip as UTC
instants; ordinary strings, including ISO-8601-looking strings, remain strings. Null values retain
the SDK's patch/clearing semantics. Unsupported objects fail with `invalid_argument` rather than
being stringified.

User values are never logged or included in errors. Applications should apply the same care to
their own UI, analytics, crash reporting, and persistence. This plugin does not normalize identity
values. User update events are not exposed in Phase 5 because the official event parity and a
dedicated public event contract have not been established. End-to-end identity conflict, server
merge, and profile persistence behavior require a valid Application Code and configured Huawei
device.

User operation failures use `user_fetch_failed`, `user_save_failed`, `personalization_failed`,
`depersonalization_failed`, `invalid_argument`, `not_initialized`, or `native_error`.

## Installation management

All installation calls require successful initialization. `getInstallation()` returns the Huawei
SDK's local snapshot without network access. `fetchInstallation()` waits for a server refresh, and
`saveInstallation()` waits for the native save callback:

```dart
final local = await InfobipMobileMessagingHuawei.getInstallation();
final refreshed = await InfobipMobileMessagingHuawei.fetchInstallation();
await InfobipMobileMessagingHuawei.saveInstallation(refreshed);

final registrationEnabled = local.pushRegistrationEnabled;
```

`isPrimaryDevice` and `customAttributes` are writable. Push registration state and ID, language,
notification permission state, app user ID, and device/application/OS/SDK
metadata are native-managed and are never sent by `saveInstallation()`. The push registration ID
matches the official Installation model and may be read by an application, but this plugin does not
expose a raw HMS token or token setter and the example does not display identifiers.

Installation custom attributes use the same codec as User attributes: strings, booleans, numbers,
UTC-instant `DateTime` values, and lists containing those values are supported. Unsupported values
fail with `invalid_argument`. Installation objects, identifiers, app user IDs, and custom values are
not logged or included in errors.

`onInstallationUpdated` maps Huawei `INSTALLATION_UPDATED`, while `onRegistrationUpdated` now
maps Huawei `REGISTRATION_UPDATED` to the complete typed `Installation` rather than the temporary
Phase 4 flag wrapper. Actual fetch/save persistence and event delivery require a configured Huawei
application, valid Infobip Application Code, device, and network. Failure codes are
`installation_fetch_failed`, `installation_save_failed`, `invalid_argument`, `not_initialized`,
and `native_error`.

## Native dependencies

The Android library pins the official 8.14.0 artifacts:

```kotlin
implementation("com.infobip:infobip-mobile-messaging-huawei-sdk:8.14.0@aar") {
    isTransitive = true
}
implementation("com.infobip:infobip-mobile-messaging-huawei-inbox-sdk:8.14.0@aar") {
    isTransitive = true
}
implementation("com.infobip:infobip-mobile-messaging-huawei-chat-sdk:8.14.0@aar") {
    isTransitive = true
}
```

The AAR notation and transitive resolution follow the 8.14.0 Huawei SDK integration form. The Huawei Maven repository is configured because transitive HMS artifacts are resolved from it.

`com.huawei.hms:push` and `com.huawei.hms:hmscoreinstaller` are not repeated as direct plugin dependencies. They are native SDK transitive dependencies, and `isTransitive = true` preserves them. This avoids the reusable plugin overriding a host application's resolution with duplicate declarations. A host that must enforce `push:6.11.0.300` and `hmscoreinstaller:6.7.0.300` should do so in its dependency constraints after confirming compatibility for the complete application dependency graph.

## Host application Huawei setup

Huawei configuration is an application concern, not a library concern. Before enabling Huawei push functionality, the host application must:

1. Register the Android application in Huawei AppGallery Connect.
2. Download its real `agconnect-services.json` into the host application's `android/app/` directory. For this example that path is `example/android/app/agconnect-services.json`.
3. Add the Huawei Maven repository (`https://developer.huawei.com/repo/`) to dependency resolution.
4. Add the Huawei AGConnect Gradle plugin to the host build and apply it to the host application module, following the current Huawei documentation.
5. Configure signing/package identity in the host application and provide its Infobip Application Code at runtime.

No AGConnect file, credential, signing key, or Infobip Application Code belongs in this repository. The Phase 1 example intentionally does not apply the AGConnect plugin, so it can validate plugin integration without fake credentials.

## Example

The `example/` application accepts its Application Code through a compile-time environment value and shows loading, success, and sanitized failure states. No credential is committed:

```sh
cd example
flutter run --dart-define=INFOBIP_APPLICATION_CODE=YOUR_APPLICATION_CODE
```

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter pub get
flutter build apk --debug
```

## Planned features

- Chat

These remain roadmap items, not current capabilities.

## Roadmap

1. **Phase 1:** project setup, dependency baseline, platform-channel infrastructure, documentation, and example integration.
2. **Phase 2:** analyze the official Flutter API against the Huawei native API and populate `API_COMPATIBILITY.md`.
3. **Phase 3:** core SDK initialization, idempotent state coordination, structured failures, tests, and example integration.
4. **Phase 4:** SDK-owned push lifecycle and notification events.
5. **Phase 5:** User Management.
6. **Phase 6:** Installation Management and installation events.
7. **Phase 7:** Inbox fetch, filters, counters, message mapping, and seen updates.
8. **Later phases:** implement and test approved Chat areas incrementally.

## Current limitations

- Android/Huawei only; no iOS implementation is registered.
- No public registration control, raw HMS token, Chat, notification-permission, or background-isolate API is implemented.

## Inbox

Inbox uses the initialized Mobile Messaging lifecycle and never initializes the SDK implicitly:

```dart
final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
  externalUserId: externalUserId,
  options: InboxFilterOptions(
    from: DateTime.now().subtract(const Duration(days: 30)),
    to: DateTime.now(),
    topic: 'news',
    limit: 20,
  ),
);

await InfobipMobileMessagingHuawei.setInboxMessagesSeen(
  externalUserId: externalUserId,
  messageIds: inbox.messages
      .where((message) => !message.seen)
      .map((message) => message.messageId)
      .toList(),
);
```

The caller must supply the same non-empty external user ID used for the Inbox audience. The plugin
does not derive it from the locally personalized user. The official Flutter Inbox API also supports
JWT-authorized fetches, so an optional `jwt` can be supplied to `fetchInbox`; it is forwarded to the
Huawei token overload for that request and is never stored or logged.

`Inbox` contains the server-authoritative `countTotal`, `countUnread`, `countTotalFiltered`, and
`countUnreadFiltered` values and the returned
`InboxMessage` collection. Messages expose the supported intersection of the Flutter and Huawei
models: identifier, title, body, topic, seen state, received timestamp, custom payload, deep link,
and silent flag. Timestamps are converted as UTC instants and nested payloads are restricted to
platform-channel-safe values.

Huawei Inbox 8.14.0 supports either `topic` or `topics`, date bounds, and a result limit. Single and
multiple topic filters are mutually exclusive and empty topic values are rejected. The limit is
server-side; it is not a page number, offset, or cursor, and the plugin does not paginate locally.
The native SDK exposes seen state and a server-confirmed set-seen operation, but no equivalent
separate read state, so this plugin does not invent mark-read behavior. Huawei 8.14.0 defines
`MobileInboxEvent.INBOX_MESSAGES_FETCHED`, `INBOX_COUNT_UNREAD`, `INBOX_COUNT_TOTAL`, and
`INBOX_SEEN_REPORTED`. This wrapper intentionally does not expose them because no approved official
Flutter public Inbox event parity was established. Existing notification events remain unchanged
and never mark Inbox messages seen automatically.

Inbox content can be sensitive. The plugin does not log messages, identifiers, topics, payloads, or
deep links and does not include them in errors. Actual retrieval, counters, personalization rules,
and seen updates require validation with a configured Infobip application, Inbox data, network, and
a Huawei-capable device.

- A real Application Code, configured AGConnect/Huawei application, and compatible Huawei device are required to validate token acquisition, notification display, tap intents, actions, and server registration end to end.

API compatibility has been assessed in `API_COMPATIBILITY.md`. See `CONTRIBUTING.md` for development requirements and `INFOBIP_PHASES.md` for the broader work plan.
