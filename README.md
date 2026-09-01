# Infobip Mobile Messaging Huawei for Flutter

An Android-only Flutter plugin being developed as a Flutter-facing wrapper for the official Infobip Huawei Mobile Messaging SDK.

> **Phase 1 status:** project and channel infrastructure only. Infobip initialization, push, notifications, users, installations, Inbox, and Chat are **not implemented**.

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
                -> Infobip Huawei SDK (future phases)
```

Channel names are centralized on both platforms. The method channel is reserved for commands and request/response operations; the event channel is registered for future asynchronous notification and Chat events. The native handler deliberately returns `notImplemented` for every method in Phase 1.

The Dart source currently contains only the useful `core` and `platform` boundaries. Future feature work will introduce `notifications`, `user`, `installation`, `inbox`, `chat`, and `models` as those APIs are designed. Native feature packages will follow the same incremental approach rather than adding empty placeholders.

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

Huawei configuration is an application concern, not a library concern. Before enabling Huawei functionality in a future phase, the host application must:

1. Register the Android application in Huawei AppGallery Connect.
2. Download its real `agconnect-services.json` into the host application's `android/app/` directory. For this example that path is `example/android/app/agconnect-services.json`.
3. Add the Huawei Maven repository (`https://developer.huawei.com/repo/`) to dependency resolution.
4. Add the Huawei AGConnect Gradle plugin to the host build and apply it to the host application module, following the current Huawei documentation.
5. Configure signing/package identity in the host application and configure its Infobip Application Code when feature implementation requires it.

No AGConnect file, credential, signing key, or Infobip Application Code belongs in this repository. The Phase 1 example intentionally does not apply the AGConnect plugin, so it can validate plugin integration without fake credentials.

## Example

The `example/` application imports the plugin through a local path and displays an integration status screen. It does not call the Infobip or Huawei APIs.

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter pub get
flutter build apk --debug
```

## Planned features

- Core Mobile Messaging
- Push notifications and notification events
- User management
- Installation management
- Inbox
- Chat

These are roadmap items, not current capabilities. API compatibility will be assessed before any public feature API is introduced.

## Roadmap

1. **Phase 1:** project setup, dependency baseline, platform-channel infrastructure, documentation, and example integration.
2. **Phase 2:** analyze the official Flutter API against the Huawei native API and populate `API_COMPATIBILITY.md`.
3. **Later phases:** implement and test approved feature areas incrementally, including device-level Huawei validation.

See `CONTRIBUTING.md` for development requirements and `INFOBIP_PHASES.md` for the broader work plan.
