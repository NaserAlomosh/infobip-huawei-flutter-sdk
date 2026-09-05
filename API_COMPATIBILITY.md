# API Compatibility

This document summarizes the public API coverage of
`infobip_mobilemessaging_huawei` v1.0.0 against the Infobip Huawei
Mobile Messaging Android SDK 8.14.0.

The package is Android-only and targets Huawei Mobile Services (HMS).

## Status Legend

| Status | Meaning |
| --- | --- |
| **Supported** | Exposed with equivalent behavior. |
| **Adapted** | Supported through a Flutter-specific model, Future, Stream, or native Android bridge. |
| **Unsupported** | Not available in Huawei SDK 8.14.0 or not supported by this package. |
| **Intentionally omitted** | Available natively but intentionally not part of the stable v1 public API. |

---

## Core

| Capability | Status | Notes |
| --- | --- | --- |
| Initialize with Application Code | **Adapted** | Asynchronous and application-context scoped. |
| Configure JWT | **Adapted** | `setJwt` sets or clears the in-memory JWT used by supported requests. |
| SDK shutdown / reset | **Unsupported** | Flutter engine detachment does not reset the native SDK singleton. |

---

## Platform Support

| Capability | Status | Notes |
| --- | --- | --- |
| Android + Huawei Mobile Services | **Supported** | Android API 26+. |
| iOS | **Unsupported** | No iOS implementation is included. |
| Firebase / FCM | **Unsupported** | This package is specifically for Huawei/HMS. |

---

## Push Notifications

| Capability | Status | Notes |
| --- | --- | --- |
| Remote notification registration | **Adapted** | Host app owns runtime permission; Infobip SDK owns HMS token handling. |
| Message received | **Adapted** | Exposed through typed Flutter events. |
| Notification tapped | **Adapted** | Latest pending notification tap may replay once after subscription. |
| Notification action tapped | **Adapted** | Exposed through typed Flutter events. |
| Registration updates | **Adapted** | Exposes updated `Installation`. |
| Installation updates | **Adapted** | Exposes updated `Installation`. |
| Raw token injection | **Unsupported** | HMS and the Infobip SDK own token acquisition and refresh. |
| Background Dart isolate callback | **Unsupported** | Native processing remains available, but no Dart background handler is registered. |

---

## User Management

| Capability | Status | Notes |
| --- | --- | --- |
| Get cached user | **Supported** | Returns the locally cached SDK user. |
| Fetch user | **Supported** | Server fetch exposed as a `Future`. |
| Save user | **Supported** | Supported user properties and custom attributes can be updated. |
| Personalize user | **Adapted** | Maps Flutter identity and attributes to Huawei SDK models. |
| Depersonalize user | **Adapted** | Disconnects the current user identity. |
| Delete server user | **Unsupported** | Depersonalization is not server-side user deletion. |

---

## Installation Management

| Capability | Status | Notes |
| --- | --- | --- |
| Get cached installation | **Supported** | Returns local SDK installation state. |
| Fetch installation | **Supported** | Server refresh exposed as a `Future`. |
| Save installation | **Adapted** | Only supported writable fields are accepted. |
| Primary device state | **Adapted** | Can be updated where supported by the SDK. |
| Custom attributes | **Adapted** | Supports Huawei-compatible scalar/date/list values. |
| Delete installation | **Unsupported** | No public v1 installation-deletion API. |

---

## Mobile Inbox

| Capability | Status | Notes |
| --- | --- | --- |
| Fetch Inbox | **Adapted** | External user ID is explicit. |
| Filter messages | **Adapted** | Supports time, topic, and result-limit filters. |
| Inbox counters | **Adapted** | Returned with server-backed Inbox data. |
| Mark message as seen | **Adapted** | Uses the native Inbox SDK operation. |
| Optional request JWT | **Adapted** | Supported for authenticated Inbox requests. |
| Offline-authoritative Inbox | **Unsupported** | Inbox state remains server-backed. |
| Native Inbox event stream | **Intentionally omitted** | Not part of the stable v1 Flutter API. |

---

## In-App Chat

### UI

| Capability | Status | Notes |
| --- | --- | --- |
| Embedded native Chat UI | **Adapted** | Uses `InAppChatFragment` through a Flutter PlatformView. |
| Native message composer | **Supported** | Composer remains fully native. |
| Native attachment picker | **Supported** | Attachment handling remains native. |
| Chat back navigation | **Adapted** | Controller reports whether native Chat consumed the back action. |
| Chat scrolling | **Adapted** | Flutter gesture handling is configured for the embedded native view. |

### Chat APIs

| Capability | Status | Notes |
| --- | --- | --- |
| Unread message count | **Adapted** | Current value exposed as a `Future`. |
| Unread count updates | **Adapted** | Exposed as a Flutter stream. |
| Send text message | **Adapted** | Requires an attached Chat view. |
| Send contextual data | **Adapted** | Requires an attached Chat view. |
| Language | **Adapted** | View-scoped native widget configuration. |
| Widget theme | **Adapted** | View-scoped native widget configuration. |
| Programmatic attachments | **Intentionally omitted** | Android URI ownership and permission semantics are not part of v1. |
| Thread APIs | **Intentionally omitted** | Stable thread models are not exposed in v1. |
| Raw Chat messages | **Intentionally omitted** | v1 does not expose raw component messages. |
| Additional Chat runtime events | **Intentionally omitted** | Only stable v1 Chat events are exposed. |

---

## Public Models

### Notifications

`Message` mirrors the official shared notification model. Huawei-backed values
include message presentation, timestamps, seen state, URL actions, custom
payload, and Chat state. `originalPayload` and `internalData` remain nullable
because Huawei 8.14.0 cannot provide the official platform-specific values.
`PushMessage` is a deprecated source-compatible alias.

### User

- `UserData` (`User` remains a deprecated alias)
- `UserIdentity`
- `UserAttributes`

These models expose supported Infobip profile and identity fields.

Birthday values retain date-only semantics, while custom `DateTime` attributes
represent UTC timestamps.

### Installation

`Installation`

Represents SDK-managed device and registration information.

Only fields explicitly supported for modification by the plugin can be updated.

### Inbox

- `Inbox`
- `Message` (`InboxMessage` remains a deprecated alias)
- `FilterOptions` (`InboxFilterOptions` remains a deprecated alias)

Supports server counters, Inbox messages, time filters, topic filters, and result
limits.

### Chat

- `InfobipHuaweiChatMessagePayload`
- `InfobipHuaweiChatError`

`InfobipHuaweiChatMessagePayload` represents outbound text messages.

`InfobipHuaweiChatError` represents typed Chat view lifecycle and availability
errors.

---

## Data Type Constraints

Custom User and Installation attributes support Huawei SDK 8.14.0 compatible
values:

- `String`
- `bool`
- numeric values
- dates
- lists containing supported scalar values

Native Android SDK objects are converted into Flutter-safe models and are never
exposed directly.

---

## Event Delivery

Notification events are not treated as a persistent event queue.

The latest pending notification tap may be replayed once after Flutter
subscribes. Other notification events are delivered only while the Flutter
engine and event subscriber are active.

---

## Chat Requirements

In-App Chat requires:

- successful Infobip SDK initialization
- an Android `FragmentActivity`
- Chat enabled for the configured Infobip application/profile
- a compatible Huawei Android environment

Chat is exposed primarily as a native UI integration rather than a headless
conversation API.
## Model Parity

The parity audit uses official Flutter commit
`8b630d0f736d400635317131d549c345349bd54d` and Huawei SDK 8.14.0
(reference revision `83786a498f165386041bf75e71488f1635f8af94`).

| Official Flutter API/model | Official field/method | Huawei native equivalent | Plugin equivalent | Status | Required action |
| --- | --- | --- | --- | --- | --- |
| `Message` | `messageId`, `title`, `body`, `sound`, `vibrate`, `icon`, `silent`, `category` | `Message` getters | Same fields | EXACT | None |
| `Message` | `customPayload`, `contentUrl` | `Message.customPayload`, `contentUrl` | Same fields | EXACT | Channel-safe conversion |
| `Message` | `receivedTimestamp`, `seenDate`, `seen` | timestamps and `seenTimestamp != 0` | UTC `DateTime` and boolean | MAPPABLE | Map native timestamps |
| `Message` | `browserUrl`, `deeplink`, `webViewUrl` | corresponding `Message` getters | Same fields | EXACT | None |
| `Message` | `inAppOpenTitle`, `inAppDismissTitle`, `chat` | corresponding `Message` getters | Same fields | EXACT | None |
| `Message` | `internalData` | Not exposed by the Huawei 8.14 public message contract | Nullable field | NOT_AVAILABLE_IN_HUAWEI | Return `null` |
| `Message` | `originalPayload` | APNS payload | Nullable field | IOS_ONLY | Return `null`; never synthesize APNS data |
| `PushMessage` | legacy class name | Same native message | Deprecated alias of `Message` | RENAMED | Migrate to `Message` |
| `Installation` | registration, device, SDK, application, OS and user fields | corresponding Huawei `Installation` getters | Official field names | EXACT | None |
| `Installation` | `pushServiceType` | Huawei `PushServiceType` | `PushServiceType.HMS` | HUAWEI_ONLY | Preserve HMS enum value |
| `Installation` | `isPrimaryDevice`, `isPushRegistrationEnabled`, `customAttributes` | `InstallationJson.fromJSON` writable set | Mutable properties | EXACT | Save only these properties |
| `Installation` | old shortened field names | N/A | Deprecated getters/constructor parameters | RENAMED | Migrate to official names |
| `UserData` | identity and profile fields | `User`, `UserIdentity`, `UserAttributes` | Same names and types | MAPPABLE | Convert native sets to Dart lists |
| `UserData` | `type` | Huawei user type | `Type` | MAPPABLE | Encode/decode native value |
| `UserData` | `installations` | `User.installations` | `List<Installation>?` | MAPPABLE | Use aligned installation codec |
| `User` | legacy plugin class name | Huawei `User` | Deprecated alias of `UserData` | RENAMED | Migrate to `UserData` |
| `PersonalizeContext` | all fields | Huawei personalization context | Same fields | EXACT | Use as primary personalize argument |
| `Inbox` | counters and `messages` | Huawei Mobile Inbox | Same counters and `List<Message>` | MAPPABLE | Reuse shared message model |
| `FilterOptions` | `fromDateTime`, `toDateTime`, `topic`, `limit` | `MobileInboxFilterOptions` | Same fields | EXACT | Convert dates to UTC |
| `FilterOptions` | multiple topics | Huawei list-topic constructor | `topics` | HUAWEI_ONLY | Retain supported extension |
| `InboxFilterOptions`, `from`, `to` | legacy plugin names | Same native filters | Deprecated aliases | RENAMED | Migrate to official names |
| `LibraryEvent` message payloads | `Message` | Huawei broadcasts | Typed `Stream<Message>` | BEHAVIOR_DIFFERENCE | Keep typed stream architecture |
| `LibraryEvent` installation payloads | `Installation` | Huawei broadcasts | Typed `Stream<Installation>` | MAPPABLE | Keep typed stream architecture |
| Firebase configuration | Firebase options | No Huawei equivalent | Not exposed | GOOGLE_ONLY | Intentionally omit |
| iOS configuration | iOS options | No Android equivalent | Not exposed | IOS_ONLY | Intentionally omit |
| Huawei initialization | Application Code | Huawei SDK initialization | `initialize(applicationCode:)` | ANDROID_ONLY | Retain coherent Huawei API |
| Chat models | Chat UI/runtime models | Huawei Chat 8.14 | Existing view/controller models | BEHAVIOR_DIFFERENCE | Defer feature expansion to development-v2 |

### Compatibility aliases

Deprecated aliases preserve pre-v1 source compatibility for `PushMessage`,
`User`, `InboxMessage`, `InboxFilterOptions`, `deepLink`, `isSilent`,
`pushRegistrationEnabled`, `applicationVersion`, `operatingSystem`,
`operatingSystemVersion`, `deviceTimezoneId`, and `appUserId`. Canonical code
should use the official-style names.
