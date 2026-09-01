# Contributing

## Architecture

- Keep the public Dart API independent of `MethodChannel` and `EventChannel` details.
- Route platform operations through the platform interface and central channel contract.
- Add Dart and Kotlin feature boundaries only when implementing a real, reviewed capability.
- Keep the Android plugin lifecycle-safe and release channel handlers on engine detachment.
- Do not add an iOS implementation unless the supported-platform decision changes explicitly.

## Public API stability

Public APIs must be intentional, strongly typed, documented, and supported by a compatibility assessment. Avoid exposing provisional methods or native implementation details. Treat published names and behavior as compatibility commitments.

## Dependency management

- Keep Android and Dart dependencies minimal and relevant to this reusable plugin.
- Pin Infobip SDK modules to the reviewed baseline.
- Do not silently upgrade Infobip, Huawei, Flutter, Kotlin, Gradle, or Android Gradle Plugin versions.
- Review release notes, transitive dependencies, repository requirements, and host-app impact for every SDK upgrade.
- Do not add application-specific SDKs, AARs, signing configuration, multidex configuration, or unrelated build plugins.

## Formatting and analysis

Run before committing:

```sh
dart format .
flutter analyze
```

Kotlin must remain idiomatic, null-safe, lifecycle-aware, and compatible with Java 17. Do not block the Android main thread.

## Testing

Run `flutter test` for the package and example. Add focused platform-interface tests for channel infrastructure and native tests when Kotlin behavior is introduced. Tests must not imply that an unimplemented Infobip feature works. Device-dependent functionality must eventually be tested on a supported Huawei device.

## Credentials and security

Never commit `agconnect-services.json`, Infobip Application Codes, secrets, credentials, keystores, signing passwords, or production payloads. Keep host-application identity and AGConnect configuration outside the plugin. Verify ignored files with `git status` before each commit.

## Native code

The Android module is a library and must not declare an `applicationId`. Keep channel identifiers and method identifiers centralized. Map errors and models at the platform boundary, release listeners on detach, and invoke native SDK APIs only after their lifecycle and threading requirements have been reviewed.

## SDK upgrades

An SDK upgrade requires an explicit change, release-note review, dependency-graph verification, compatibility-table update, analysis, tests, and an Android build. Never use a dynamic dependency version.
