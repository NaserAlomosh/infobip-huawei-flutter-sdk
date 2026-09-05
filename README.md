# Infobip Mobile Messaging Huawei for Flutter

An Android-only Flutter plugin being developed as a Flutter-facing wrapper for the official Infobip Huawei Mobile Messaging SDK.

> **Phase 9 status:** Core initialization, notifications, User Management, Installation Management, Inbox, and embedded Chat are implemented and SDK-wide model/channel contracts are hardened.

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

Chat uses Huawei SDK 8.14.0's `InAppChatFragment` through a dedicated Android PlatformView. The fragment retains the Infobip native composer, attachment workflow, focus handling, validation, and upload lifecycle. It is hosted by the application's AndroidX `FragmentActivity`.

### Chat JWT authentication

Register the root Chat JWT provider before Chat needs to authenticate:

```dart
await InfobipMobileMessagingHuawei.setChatJwtProvider(
  () async {
    return await myBackend.getFreshInfobipChatJwt();
  },
  (error) {
    // Optional host-side error handling.
  },
);
```

Huawei Chat can request authentication more than once during its lifecycle, including after a
network reconnection. The callback is invoked on demand for every native request and must return a
fresh, valid JWT each time; do not return a cached token that may have expired. JWT generation and
signing belong to the host application's trusted backend. The plugin neither generates nor signs,
persists, or logs Chat JWTs.

`setJwt()` configures Mobile Messaging and Inbox authorization and is not the Chat authentication
API. Chat authentication uses only `setChatJwtProvider()`. Root `cleanup()` clears the native Chat
provider and its pending requests, and clears the Dart callback, so register the provider again
after reinitialization.

The Android host activity must extend `FlutterFragmentActivity` (or another
AndroidX `FragmentActivity`) rather than `FlutterActivity` so the native Chat
fragment can be attached safely.

Initialize the core SDK successfully before constructing Chat, then place the widget in any bounded Flutter layout:

```dart
final chatController = InfobipHuaweiChatController();

Scaffold(
  appBar: AppBar(
    title: const Text('Support'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () async {
        final handled =
            await chatController.navigateBackOrCloseChat();
        if (!handled && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    ),
  ),
  body: InfobipHuaweiChatView(
    controller: chatController,
    withInput: true,
    withToolbar: false,
    onError: (error) {
      // Update Flutter-owned UI with a friendly availability message.
    },
  ),
);
```

`withInput` controls the native Infobip message composer and defaults to
`true`. `withToolbar` controls the native Infobip toolbar and defaults to
`false`, allowing the Flutter application to provide its own `AppBar`. Existing
calls that omit both options retain these defaults.

For Flutter-owned back navigation, call `navigateBackOrCloseChat()` first and pop the Flutter route only when it returns `false`. A controller is bound to one PlatformView ID, is detached when its widget is disposed, and never targets a global or previously disposed Chat view. Each view uses the SDK-managed Chat singleton; the plugin does not create another `MobileMessaging` instance.

`onError` receives an `InfobipHuaweiChatError` with a typed
`InfobipHuaweiChatErrorCode`: `notInitialized`, `activityUnavailable`,
`activityFragmentUnavailable`,
`chatUnavailable`, `nativeError`, or `unknown`. Unknown future native codes and malformed payloads
map safely to `unknown`. Creation and view-lifecycle availability failures invoke `onError` once
per native view instance; the native placeholder stays visually neutral so the application can
own its error presentation. Android-only behavior is unchanged on unsupported platforms, where
the widget continues to show its existing static availability message rather than reporting a
native lifecycle error.

The callback describes the embedded view lifecycle. An explicit controller operation such as
`navigateBackOrCloseChat()` instead completes its `Future` with `PlatformException` when its
attached native view cannot execute the command. Such command failures are not also sent to
`onError`, avoiding duplicate notifications.

Creation without completed initialization reports `notInitialized`; creation while no Activity is
attached reports `activityUnavailable`. Native controller operation failures use the
`chat_unavailable` platform error code and do not include URLs, thread data, attachment paths,
tokens, or stack traces.

Global unread state is available independently of an embedded view:

```dart
final available = await InfobipMobileMessagingHuawei.chat.isChatAvailable();
final current = await InfobipMobileMessagingHuawei.chat.getMessageCounter();
await InfobipMobileMessagingHuawei.chat.resetMessageCounter();
final subscription = InfobipMobileMessagingHuawei
    .chat
    .onUnreadMessageCounterUpdated
    .listen((count) { /* update Flutter-owned UI */ });
```

`getUnreadMessageCount()` remains available as a backward-compatible alias for
`getMessageCounter()` and uses the same native counter query.

The method returns `Future<int>` and never substitutes zero for an error. Calls before successful
initialization fail with `not_initialized`; unavailable Chat and native failures use
`chat_unavailable` and `native_error`. Updates use the shared global event channel, are delivered on
the Android main thread, and are not replayed or deduplicated. Use the method for current state and
the stream for future updates. Malformed and negative updates are ignored without closing the
stream. One global Huawei listener is installed after initialization and removed at engine detach;
creating or disposing embedded views does not register listeners.

No other Chat events are public. Thread, raw-message, loading/connection, and component UI callbacks are omitted:
thread/raw events lack stable public models, while view and control callbacks belong to a specific
embedded component rather than global Chat state. Native attachments remain available from the
native composer.

The controller also exposes the component-scoped text and contextual-data commands:

```dart
await chatController.send(
  const InfobipHuaweiChatMessagePayload.text('Hello'),
);
await chatController.sendContextualData('{"source":"support"}');

await chatController.setLanguage('ar-AE');
final language = await chatController.getLanguage();

await chatController.setWidgetTheme('configured-theme');
final widgetTheme = await chatController.getWidgetTheme();

final multithread = await chatController.isMultithread();
```

`InfobipHuaweiChatMessagePayload` is deliberately a send payload and not a received-message model.
Its current portable surface is non-empty text only. Programmatic attachments are omitted because
Huawei's attachment contract is based on Android URI/file lifecycle concerns; the native composer
remains the default and supported attachment workflow. Contextual data stays distinct from a Chat
message, is treated as opaque text, and is never included in plugin logs or error details. Both
commands require a live attached view and otherwise fail with `chat_unavailable`; invalid empty
values fail with `invalid_argument` at the native boundary (and `ArgumentError` in Dart).

Language and widget theme remain component-scoped. Language uses an Infobip widget language code
such as `en-US` or `ar-AE`; Android resolves that code with
`LivechatWidgetLanguage.findLanguage(...)` before calling Huawei's enum-based API, then maps the
returned enum's `widgetCode` back to Dart. Unsupported codes fail with `invalid_argument` instead of
falling back to English. Widget theme continues to use Huawei's string identifier. Dart does not
persist either setting or apply it to future views. A widget theme is not Android `Theme`, a resource
ID, or Flutter `ThemeData`. `getWidgetTheme()` returns `null` when Huawei reports
that no explicit widget theme is active; absence is not treated as a native failure.

Thread commands remain intentionally omitted. Huawei 8.14.0 exposes them on the embedded component,
but the inspected official Flutter source does not provide the stable thread models and operation
result contract needed for a compatible permanent Dart API. In particular, this plugin does not
claim headless history access or cache raw native thread objects.

Huawei 8.14.0 provides root SDK cleanup through `MobileMessaging.cleanup()`. The separate
`InAppChat.cleanup()` operation only removes In-App Chat data and is not used to implement root
cleanup.

Android PlatformViews require real-device validation for IME resizing, accessibility, attachment permissions, Activity recreation, and route leave/re-entry behavior. No manual keyboard workaround is installed. Chat also requires a correctly configured Infobip application/backend and a Huawei device or suitable HMS environment. Never log Chat content, contextual data, URLs, identity, tokens, or local attachment paths.

## Initialization

Provide the Application Code issued for your Infobip application:

```dart
await InfobipMobileMessagingHuawei.initialize(
  applicationCode: 'APPLICATION_CODE',
);
```

The application code must be non-empty. Initialization is asynchronous and uses Android's application context. Concurrent calls with the same code share one native build, and after success later equivalent calls complete without rebuilding. Calls with a different code are rejected with `already_initialized`, including after a failed attempt. A failed initialization can be retried by calling `initialize` again with the same application code; the retry starts a new native build. Failures cross the channel as `PlatformException` with stable codes: `invalid_argument`, `already_initialized`, `initialization_failed`, or `native_error`.

Use root cleanup only when resetting all local SDK state, such as before switching Application
Codes, then initialize again before further SDK calls:

```dart
await InfobipMobileMessagingHuawei.cleanup();

await InfobipMobileMessagingHuawei.initialize(
  applicationCode: 'NEW_APPLICATION_CODE',
);
```

Cleanup clears the plugin's in-memory global JWT, the native SDK JWT supplier, and the Chat JWT
provider before invoking
`MobileMessaging.cleanup()`. It is not a logout operation; use `depersonalize()` for normal
user/session flows. After successful cleanup, operations that require initialization fail with
`not_initialized` until `initialize` succeeds again.

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
InfobipMobileMessagingHuawei.notifications.onUserUpdated;
InfobipMobileMessagingHuawei.notifications.onPersonalized;
InfobipMobileMessagingHuawei.notifications.onDepersonalized;
```

Messages contain only message ID, title, body, channel-safe custom payload, deep link, and silent status. Registration and installation updates carry a typed `Installation`. They are not retained for cold-start replay.

User update and personalization events carry the same typed `User` model returned by the user
management APIs. Depersonalization emits `void` and does not fabricate a user payload. These
lifecycle events use the existing shared event channel and are not buffered.

Native listeners are installed once per Flutter engine and removed on detach. Flutter sink delivery is marshalled to Android's main thread. The most recent notification tap is retained when Dart is not listening, replaces any earlier pending tap, is replayed once on listen, and is then cleared. Other events are not buffered.

There is no background Dart isolate. The native SDK can continue its own processing and notification display while Flutter is stopped, but no Dart callback executes while the application is terminated.

Android notification permission and Infobip registration are separate concerns. After obtaining Android notification permission, call `InfobipMobileMessagingHuawei.registerForRemoteNotifications()` to trigger Infobip SDK registration. The plugin does not request permission; the host owns the permission declaration, rationale, and request UX.

Registration readiness is determined from the SDK installation identifier:

```dart
await InfobipMobileMessagingHuawei.registerForRemoteNotifications();
final installation = await InfobipMobileMessagingHuawei.getInstallation();
final ready = installation.pushRegistrationId?.isNotEmpty == true;
```

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
values. End-to-end identity conflict, server
merge, and profile persistence behavior require a valid Application Code and configured Huawei
device.

User operation failures use `user_fetch_failed`, `user_save_failed`, `personalization_failed`,
`depersonalization_failed`, `invalid_argument`, `not_initialized`, or `native_error`.

## Custom events

Custom events use a typed model whose definition and properties match the Huawei 8.14.0
`CustomEvent` contract:

```dart
final event = InfobipHuaweiCustomEvent(
  definitionId: 'purchase',
  properties: {'amount': 29.99, 'completed': true},
);

await InfobipMobileMessagingHuawei.submitEvent(event);
final submitted =
    await InfobipMobileMessagingHuawei.submitEventImmediately(event);
```

`submitEvent()` calls the Huawei non-callback overload and queues the event. The Flutter-facing
`submitEventImmediately()` name follows the official Flutter API and calls Huawei's callback-based
`submitEvent(CustomEvent, ResultListener<CustomEvent>)` overload; its future completes only after
the native callback succeeds. Returned events can include the server-assigned `eventId` and
`createdAt`. Properties support strings, booleans, numbers, UTC `DateTime` values, and lists of
those values. Native callback failures retain the Huawei error code and message in the resulting
`PlatformException`.

## Installation management

All installation calls require successful initialization. `getInstallation()` returns the Huawei
SDK's local snapshot without network access. `fetchInstallation()` waits for a server refresh, and
`saveInstallation()` waits for the native save callback:

```dart
final local = await InfobipMobileMessagingHuawei.getInstallation();
final refreshed = await InfobipMobileMessagingHuawei.fetchInstallation();
await InfobipMobileMessagingHuawei.saveInstallation(refreshed);

final installations = await InfobipMobileMessagingHuawei
    .depersonalizeInstallation(local.pushRegistrationId!);
final updatedPrimaryState = await InfobipMobileMessagingHuawei
    .setInstallationAsPrimary(
      pushRegistrationId: local.pushRegistrationId!,
      isPrimary: false,
    );

final registrationEnabled = local.pushRegistrationEnabled;
```

The dedicated depersonalization and primary-status APIs trim and validate the push registration
ID, wait for Huawei's `ResultListener<List<Installation>>`, and return every installation supplied
by the SDK. They do not change `depersonalize()` or `saveInstallation()` behavior.

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

## Running the example

The example is an Android/Huawei-only Flutter application covering initialization, notification
events, User, Installation, Inbox, and embedded native Chat. Use Flutter 3.35.7 or later, Java 17,
and an Android/Huawei environment matching the versions in [Requirements](#requirements).

1. Register the example package with Huawei AppGallery Connect. For Huawei Push on a device, place
   your own `agconnect-services.json` at `example/android/app/agconnect-services.json` and apply the
   AGConnect Gradle plugin as described in [Host application Huawei setup](#host-application-huawei-setup).
   The Huawei Maven repository is already configured in the example.
2. Run the application with a development Infobip Application Code supplied at build time:

```sh
cd example
flutter pub get
flutter run --dart-define=INFOBIP_APPLICATION_CODE=YOUR_APPLICATION_CODE
```

Inbox external user IDs are entered at runtime and are not persisted. Use only
test identities with a development Infobip application. A Chat widget theme name is optional and
must match a theme configured for your Infobip widget; `null` means no explicit theme is active.
The embedded native composer provides its own supported attachment workflow.

On Android 13 and later, the host application is responsible for declaring and requesting runtime
notification permission with suitable rationale UX. The plugin intentionally does not expose a
permission API, and the example does not add a permission dependency solely for this purpose.

## Current limitations

- Android/Huawei only; no iOS implementation is registered.
- No raw HMS token, notification-permission, or background-isolate API is implemented.

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
does not derive it from the locally personalized user.

### Inbox JWT authorization

Infobip Production application profiles require JWT authorization for Inbox. Obtain an
Infobip-compatible JWT from the host application's trusted backend and configure it in memory:

```dart
final jwt = await myBackend.getInfobipJwt();

await InfobipMobileMessagingHuawei.setJwt(jwt);

final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
  externalUserId: userId,
  options: const InboxFilterOptions(limit: 10),
);
```

A token can instead be supplied for one fetch:

```dart
final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
  externalUserId: userId,
  jwt: jwt,
  options: const InboxFilterOptions(limit: 10),
);
```

A non-empty per-call `jwt` takes precedence over the globally configured JWT. If the per-call JWT
is absent or whitespace-only, the global JWT is used. If neither exists, the plugin preserves the
existing behavior and calls the Application Code authorization overload. Tokens are trimmed,
retained only in native process memory, never logged, and can be cleared with `setJwt(null)`.
Successful depersonalization also clears the token.

Huawei SDK 8.14.0 exposes no token overload for `MobileInbox.setSeen`. Its seen-reporting path uses
the JWT supplier configured on `MobileMessaging`, so call `setJwt` before
`setInboxMessagesSeen` when the application profile requires JWT authorization.

Do not generate production Infobip JWTs or embed signing keys in a Flutter application. An existing
application login token must not be reused unless the backend confirms that it is an
Infobip-compatible JWT generated with Infobip's required signing configuration.

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
