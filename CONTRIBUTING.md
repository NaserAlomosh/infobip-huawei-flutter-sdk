# Contributing

## Development approach

- Keep public Dart APIs minimal, strongly typed, documented, and independent of channel details.
- Route platform operations through the platform interface and central channel contract.
- Keep Android code lifecycle-safe, release handlers and listeners on detach, and avoid retaining an activity beyond its attachment lifecycle.
- Do not add iOS or non-Huawei transport support without an explicit supported-platform decision.
- Treat published names, models, channel behavior, and errors as compatibility commitments.

## Dependencies

The native implementation targets Infobip Huawei Mobile Messaging SDK 8.14.0. Do not upgrade Infobip, Huawei, Flutter, Kotlin, Gradle, or Android Gradle Plugin dependencies silently. Review release notes, transitive dependencies, repository requirements, host impact, and `API_COMPATIBILITY.md` for every SDK change. Do not add copied AARs, application-specific SDKs, signing configuration, or unrelated build plugins.

## Formatting and validation

Run from the repository root before opening a pull request:

```sh
dart format lib test example/lib example/test
flutter pub get
flutter analyze
flutter test
(
  cd example
  flutter pub get
  flutter analyze
  flutter test
  flutter build apk --debug
)
dart pub publish --dry-run
git diff --check
```

Add focused Dart tests for public and platform-channel behavior. Add native tests when Kotlin behavior changes. Device-dependent functionality must be validated on a supported Huawei device with the contributor's own ignored host configuration.

## Pull requests

Use a focused branch and a concise commit message. Describe public API or host-configuration impact, tests performed, device coverage, and any remaining limitations. Do not combine SDK upgrades with unrelated changes.

## Security

Never commit or log `agconnect-services.json`, Application Codes, JWTs, API keys, push tokens, user data, production payloads, keystores, private keys, signing passwords, Chat content, contextual data, or attachment paths. Keep host identity and AppGallery Connect configuration outside the reusable plugin. Verify ignored files and staged changes before every commit.

## Native implementation

The Android module is a library and must not declare an `applicationId`. Keep channel and method identifiers centralized, use explicit model mapping, sanitize platform errors, dispatch SDK work according to its threading requirements, and invoke features only after successful SDK initialization. Embedded Chat requires an attached `FragmentActivity` and must dispose its fragment and view-scoped channel cleanly.
