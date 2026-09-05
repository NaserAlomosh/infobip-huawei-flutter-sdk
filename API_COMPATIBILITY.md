# API Compatibility

## Scope

This document describes the public v1 surface of this Android-only wrapper relative to the official Infobip Flutter capability and the Infobip Huawei Mobile Messaging Android SDK 8.14.0. It does not promise APIs that are absent from this package.

Statuses mean:

- **Supported** — exposed with equivalent behavior.
- **Adapted** — exposed through a Flutter-safe model, asynchronous API, event stream, or Android UI bridge.
- **Unsupported** — no equivalent exists in Huawei SDK 8.14.0 or this Android-only package.
- **Intentionally omitted** — the native capability is not exposed because v1 has no stable, portable public contract.

## Capability matrix

| Area | Capability | v1 status | Notes |
| --- | --- | --- | --- |
| Core | Initialize with an Application Code | Adapted | Asynchronous, idempotent for the same code, and application-context scoped. |
| Core | Configure a memory-only JWT | Adapted | `setJwt` sets or clears the JWT used by supported native requests. |
| Core | SDK shutdown/reset | Unsupported | Engine detachment does not reset the native singleton. |
| Platforms | Android with Huawei Mobile Services | Supported | Android API 26 or later. |
| Platforms | iOS or FCM transport | Unsupported | No iOS plugin registration or Firebase implementation is included. |
| Push | Request remote-notification registration | Adapted | Host owns runtime notification permission; SDK owns HMS token handling. |
| Push | Message received | Adapted | Typed event while a Flutter engine and subscriber are active. |
| Push | Notification and action tapped | Adapted | The latest pending notification tap can replay once after subscription. |
| Push | Registration and installation updates | Adapted | Events contain a typed `Installation`. |
| Push | Raw token injection | Unsupported | HMS and the native SDK own token acquisition and refresh. |
| Push | Background Dart callback | Unsupported | No background Dart isolate is registered. |
| User | Cached fetch, server fetch, and save | Supported | Native callbacks are exposed as futures. |
| User | Personalize and depersonalize | Adapted | Identity, attributes, and force-depersonalize semantics are explicit. |
| User | Delete server user | Unsupported | Depersonalization disconnects identity; it is not user deletion. |
| Installation | Cached fetch, server fetch, and save | Adapted | Only primary-device state and custom attributes are writable. |
| Installation | Delete installation | Unsupported | No public v1 deletion operation exists. |
| Inbox | Fetch, filters, counters, and mark seen | Adapted | External user ID is explicit; a request-scoped JWT is optional. |
| Inbox | Offline-authoritative Inbox | Unsupported | Results and counters are server-backed. |
| Inbox | Native Inbox event stream | Intentionally omitted | No stable official Flutter parity is exposed by v1. |
| Chat | Embedded native Chat UI | Adapted | Hosted in a PlatformView backed by `InAppChatFragment`; requires `FragmentActivity`. |
| Chat | Native composer and attachment picker | Supported | Attachment lifecycle remains native. |
| Chat | Back navigation | Adapted | A view-scoped controller reports whether native Chat consumed the action. |
| Chat | Unread count and update stream | Adapted | Current count is a future; subsequent changes are a global stream. |
| Chat | Programmatic text send and contextual data | Adapted | Requires a live attached view; message payloads are text-only. |
| Chat | Language and widget theme | Adapted | View-scoped; values map to Huawei widget configuration. |
| Chat | Programmatic attachments | Intentionally omitted | Android URI ownership and permissions have no v1 portable model. |
| Chat | Thread commands and models | Intentionally omitted | v1 does not define a stable public thread contract. |
| Chat | Raw messages and additional component events | Intentionally omitted | Only the typed unread-counter event is public. |

## Public models

- `PushMessage` contains message ID, title, body, channel-safe custom payload, deep link, and silent status.
- `User`, `UserIdentity`, and `UserAttributes` represent identity and supported profile fields. Birthdays retain date-only semantics; custom `DateTime` values represent UTC instants.
- `Installation` exposes SDK-managed device and registration state while restricting updates to primary-device state and compatible custom attributes.
- `Inbox`, `InboxMessage`, and `InboxFilterOptions` expose server counters, messages, time/topic filters, and a result limit.
- `InfobipHuaweiChatMessagePayload` represents outbound non-empty text, not a received Chat message.
- `InfobipHuaweiChatError` reports typed embedded-view lifecycle and availability failures.

## Explicit constraints

Custom user and installation attributes support values accepted by Huawei SDK 8.14.0: strings, booleans, numbers, dates, and lists of those scalar types. Native models are converted field by field and are not exposed directly.

Notification events are not a durable queue. Except for the latest pending notification tap, events are neither buffered nor replayed. Native SDK notification processing is distinct from Dart event delivery.

Chat is a native UI integration rather than a headless conversation client. It requires successful core initialization, a compatible Android activity, and an Infobip backend with Chat enabled. Failures do not expose tokens, message content, URLs, attachment paths, or native stack traces.
