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

The audit is pinned to official Flutter commit
`8b630d0f736d400635317131d549c345349bd54d` and Huawei SDK 8.14.0
(reference revision `83786a498f165386041bf75e71488f1635f8af94`).

`Message.receivedTimestamp` and `Message.seenDate` are numeric milliseconds
since the Unix epoch. `UserData.birthday` and `UserAttributes.birthday` are
nullable `YYYY-MM-DD` strings. Huawei converts those strings to and from its
native `Date` representation without exposing `DateTime` in Dart.

`PushServiceType.APNS` is retained for official model parity but cannot be returned by the Huawei Android SDK. `PushServiceType.HMS` represents the Huawei transport and is never remapped to Firebase.

| Model | Field | Official Flutter type | Huawei native type/source | Old plugin type | New plugin type | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `Message` | `messageId` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `title` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `body` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `sound` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `icon` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `category` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `internalData` | `String?` | `Not exposed by Huawei 8.14 Message` | `String?` | `String?` | **NULL_ON_HUAWEI** |
| `Message` | `contentUrl` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `browserUrl` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `deeplink` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `webViewUrl` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `inAppOpenTitle` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `inAppDismissTitle` | `String?` | `Message / MessageJson` | `String?` | `String?` | **EXACT** |
| `Message` | `vibrate` | `bool?` | `Message / MessageJson` | `bool?` | `bool?` | **EXACT** |
| `Message` | `silent` | `bool?` | `Message / MessageJson` | `bool?` | `bool?` | **EXACT** |
| `Message` | `seen` | `bool?` | `Message / MessageJson` | `bool?` | `bool?` | **EXACT** |
| `Message` | `chat` | `bool?` | `Message / MessageJson` | `bool?` | `bool?` | **EXACT** |
| `Message` | `customPayload` | `Map<String, dynamic>?` | `Message.customPayload (JSONObject)` | `Map<String, Object?>?` | `Map<String, dynamic>?` | **CONVERTED** |
| `Message` | `originalPayload` | `Map<String, dynamic>?` | `Not available on Huawei Android` | `Map<String, Object?>?` | `Map<String, dynamic>?` | **NULL_ON_HUAWEI** |
| `Message` | `receivedTimestamp` | `num?` | `MessageJson numeric epoch milliseconds` | `DateTime?` | `num?` | **CONVERTED** |
| `Message` | `seenDate` | `num?` | `MessageJson numeric epoch milliseconds` | `DateTime?` | `num?` | **CONVERTED** |
| `Message` | `topic` | `String?` | `InboxMessage.topic` | `String?` | `String?` | **HUAWEI_EXTENSION** |
| `Installation` | `installationId` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `pushRegistrationId` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `pushServiceToken` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `sdkVersion` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `appVersion` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `os` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `osVersion` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `deviceManufacturer` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `deviceModel` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `language` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `deviceTimezoneOffset` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `applicationUserId` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `deviceName` | `String?` | `Installation / InstallationJson` | `String?` | `String?` | **EXACT** |
| `Installation` | `pushServiceType` | `PushServiceType?` | `PushServiceType (HMS on Huawei)` | `PushServiceType? (FCM alias)` | `PushServiceType? (GCM, Firebase, APNS, HMS)` | **CONVERTED** |
| `Installation` | `isPrimaryDevice` | `bool?` | `Installation / InstallationJson` | `bool?` | `bool?` | **EXACT** |
| `Installation` | `isPushRegistrationEnabled` | `bool?` | `Installation / InstallationJson` | `bool?` | `bool?` | **EXACT** |
| `Installation` | `notificationsEnabled` | `bool?` | `Installation / InstallationJson` | `bool?` | `bool?` | **EXACT** |
| `Installation` | `deviceSecure` | `bool?` | `Installation / InstallationJson` | `bool?` | `bool?` | **EXACT** |
| `Installation` | `customAttributes` | `Map<String, dynamic>?` | `Installation.customAttributes` | `Map<String, Object?>?` | `Map<String, dynamic>?` | **CONVERTED** |
| `UserData` | `externalUserId` | `String?` | `User / UserJson` | `String? final` | `String? mutable` | **CONVERTED** |
| `UserData` | `firstName` | `String?` | `User / UserJson` | `String? final` | `String? mutable` | **CONVERTED** |
| `UserData` | `lastName` | `String?` | `User / UserJson` | `String? final` | `String? mutable` | **CONVERTED** |
| `UserData` | `middleName` | `String?` | `User / UserJson` | `String? final` | `String? mutable` | **CONVERTED** |
| `UserData` | `birthday` | `String?` | `Date? formatted by UserJson as yyyy-MM-dd` | `DateTime? final` | `String? mutable` | **CONVERTED** |
| `UserData` | `gender` | `Gender?` | `UserAttributes.Gender` | `Gender? including unknown` | `Gender? (Male, Female)` | **CONVERTED** |
| `UserData` | `type` | `Type?` | `User.Type` | `Type? with non-official names` | `Type? (LEAD, CUSTOMER)` | **CONVERTED** |
| `UserData` | `phones` | `List<String>?` | `Set<String>? serialized by UserJson` | `List<String>?` | `List<String>?` | **EXACT** |
| `UserData` | `emails` | `List<String>?` | `Set<String>? serialized by UserJson` | `List<String>?` | `List<String>?` | **EXACT** |
| `UserData` | `tags` | `List<String>?` | `Set<String>? serialized by UserJson` | `List<String>?` | `List<String>?` | **EXACT** |
| `UserData` | `customAttributes` | `Map<String, dynamic>?` | `Map<String, CustomAttributeValue>?` | `Map<String, Object?>?` | `Map<String, dynamic>?` | **CONVERTED** |
| `UserData` | `installations` | `List<Installation>?` | `List<Installation>?` | `List<Installation>?` | `List<Installation>?` | **EXACT** |
| `UserIdentity` | `externalUserId` | `String?` | `UserIdentity.externalUserId` | `String? final` | `String? mutable` | **CONVERTED** |
| `UserIdentity` | `phones` | `List<String>?` | `Set<String>?` | `List<String>? final` | `List<String>? mutable` | **CONVERTED** |
| `UserIdentity` | `emails` | `List<String>?` | `Set<String>?` | `List<String>? final` | `List<String>? mutable` | **CONVERTED** |
| `UserAttributes` | `firstName` | `String?` | `UserAttributes; birthday is native Date` | `birthday was DateTime?; fields final` | `String? mutable` | **CONVERTED** |
| `UserAttributes` | `lastName` | `String?` | `UserAttributes; birthday is native Date` | `birthday was DateTime?; fields final` | `String? mutable` | **CONVERTED** |
| `UserAttributes` | `middleName` | `String?` | `UserAttributes; birthday is native Date` | `birthday was DateTime?; fields final` | `String? mutable` | **CONVERTED** |
| `UserAttributes` | `birthday` | `String?` | `UserAttributes; birthday is native Date` | `birthday was DateTime?; fields final` | `String? mutable` | **CONVERTED** |
| `UserAttributes` | `gender` | `Gender?` | `UserAttributes.Gender` | `Gender? final including unknown` | `Gender? mutable (Male, Female)` | **CONVERTED** |
| `UserAttributes` | `tags` | `List<String>?` | `Set<String>?` | `List<String>? final` | `List<String>? mutable` | **CONVERTED** |
| `UserAttributes` | `customAttributes` | `Map<String, dynamic>?` | `Map<String, CustomAttributeValue>?` | `Map<String, Object?>?` | `Map<String, dynamic>? mutable` | **CONVERTED** |
| `PersonalizeContext` | `forceDepersonalize` | `bool` | `PersonalizeContext.forceDepersonalize` | `bool` | `bool` | **EXACT** |
| `PersonalizeContext` | `userIdentity` | `UserIdentity` | `UserIdentity` | `UserIdentity` | `UserIdentity` | **EXACT** |
| `PersonalizeContext` | `userAttributes` | `UserAttributes?` | `UserAttributes?` | `UserAttributes?` | `UserAttributes?` | **EXACT** |
| `Inbox` | `countTotal` | `int` | `Inbox counters` | `int` | `int` | **EXACT** |
| `Inbox` | `countUnread` | `int` | `Inbox counters` | `int` | `int` | **EXACT** |
| `Inbox` | `countTotalFiltered` | `int` | `Inbox counters` | `int` | `int` | **EXACT** |
| `Inbox` | `countUnreadFiltered` | `int` | `Inbox counters` | `int` | `int` | **EXACT** |
| `Inbox` | `messages` | `List<Message>` | `List<InboxMessage> mapped to Message JSON` | `List<Message>` | `List<Message>` | **EXACT** |
| `FilterOptions` | `fromDateTime` | `DateTime?` | `MobileInboxFilterOptions Date?` | `DateTime?` | `DateTime?` | **EXACT** |
| `FilterOptions` | `toDateTime` | `DateTime?` | `MobileInboxFilterOptions Date?` | `DateTime?` | `DateTime?` | **EXACT** |
| `FilterOptions` | `topic` | `String?` | `MobileInboxFilterOptions topic` | `String?` | `String?` | **EXACT** |
| `FilterOptions` | `limit` | `int?` | `MobileInboxFilterOptions limit` | `int?` | `int?` | **EXACT** |
| `FilterOptions` | `topics` | `Not in official API` | `Huawei list-topic constructor` | `List<String>?` | `List<String>?` | **HUAWEI_EXTENSION** |

### Compatibility aliases

Deprecated aliases preserve pre-v1 source compatibility for `PushMessage`,
`User`, `InboxMessage`, `InboxFilterOptions`, `deepLink`, `isSilent`,
`pushRegistrationEnabled`, `applicationVersion`, `operatingSystem`,
`operatingSystemVersion`, `deviceTimezoneId`, and `appUserId`. Canonical code
should use the official-style names.
