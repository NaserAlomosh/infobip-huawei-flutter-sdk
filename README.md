# Infobip Mobile Messaging Huawei for Flutter

An Android-only Flutter plugin being developed as a Flutter-facing wrapper for the official Infobip Huawei Mobile Messaging SDK.

> **Phase 4 status:** Core initialization and verified notification events are implemented. User, Installation, Inbox, and Chat APIs are **not implemented**.

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

The official Infobip Flutter plugin exposes registration information through its Installation APIs rather than public `setRegistration` or `isRegistrationEnabled` methods. Installation APIs are intentionally deferred to Phase 6; they are not approximated by Huawei-specific public methods in the meantime.

The following typed streams wrap the SDK 8.14.0 `MESSAGE_RECEIVED`, `NOTIFICATION_TAPPED`, `ACTION_TAPPED`, and `REGISTRATION_UPDATED` events:

```dart
InfobipMobileMessagingHuawei.notifications.onMessageReceived;
InfobipMobileMessagingHuawei.notifications.onNotificationTapped;
InfobipMobileMessagingHuawei.notifications.onNotificationActionTapped;
InfobipMobileMessagingHuawei.notifications.onRegistrationUpdated;
```

Messages contain only message ID, title, body, channel-safe custom payload, deep link, and silent status. `onRegistrationUpdated` currently exposes only the registration-enabled flag; the official plugin's broader Installation-shaped registration information is deferred until the Installation phase. General `INSTALLATION_UPDATED` is also deferred to Phase 6.

Native listeners are installed once per Flutter engine and removed on detach. Flutter sink delivery is marshalled to Android's main thread. The most recent notification tap is retained when Dart is not listening, replaces any earlier pending tap, is replayed once on listen, and is then cleared. Other events are not buffered.

There is no background Dart isolate. The native SDK can continue its own processing and notification display while Flutter is stopped, but no Dart callback executes while the application is terminated.

Android notification permission and Infobip registration are separate concerns. The official plugin's `registerForAndroidRemoteNotifications()` relates to Android remote-notification/permission behavior; it is not equivalent to native `MobileMessaging.setRegistration(...)`. This plugin does not currently expose a notification-permission API, and the host owns the permission declaration, rationale, and request UX.

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

- User management
- Installation management
- Inbox
- Chat

These remain roadmap items, not current capabilities.

## Roadmap

1. **Phase 1:** project setup, dependency baseline, platform-channel infrastructure, documentation, and example integration.
2. **Phase 2:** analyze the official Flutter API against the Huawei native API and populate `API_COMPATIBILITY.md`.
3. **Phase 3:** core SDK initialization, idempotent state coordination, structured failures, tests, and example integration.
4. **Phase 4:** SDK-owned push lifecycle and notification events.
5. **Later phases:** implement and test approved User, Installation, Inbox, and Chat areas incrementally.

## Current limitations

- Android/Huawei only; no iOS implementation is registered.
- No public registration control/state query, HMS token, Installation, User, Inbox, Chat, notification-permission, or background-isolate API is implemented.
- A real Application Code, configured AGConnect/Huawei application, and compatible Huawei device are required to validate token acquisition, notification display, tap intents, actions, and server registration end to end.

API compatibility has been assessed in `API_COMPATIBILITY.md`. See `CONTRIBUTING.md` for development requirements and `INFOBIP_PHASES.md` for the broader work plan.
