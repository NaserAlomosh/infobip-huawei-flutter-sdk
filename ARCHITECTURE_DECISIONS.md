# Architecture Decisions

This document contains recommendations only. It does not define channel names, public APIs, or an
implementation contract.

## 1. Public Dart API strategy

- Treat the official Infobip Flutter plugin as the naming and ergonomics baseline, while exposing
  only behavior evidenced in Huawei SDK 8.14.0.
- Prefer asynchronous, strongly typed Dart APIs. Model all native callbacks as futures and all
  unsolicited, repeatable notifications as broadcast streams.
- Keep the default API platform-neutral. Place unavoidable HMS/Android configuration in an explicit
  Android-specific options object and report unsupported iOS use clearly.
- Add APIs incrementally by module. Do not publish placeholders for Chat data capabilities that the
  native SDK cannot provide.

## 2. APIs to mirror exactly

Mirror the official plugin's intent and naming where semantics match: initialization with an
application code; registration enablement; cached/fetched/saved User and Installation operations;
personalize/depersonalize; message, notification-tap, registration, user and installation events;
Inbox fetch/filters/counts/seen state; native Chat presentation; and unread-count observation.
Exact mirroring includes nullability and asynchronous behavior only when Huawei 8.14.0 can preserve
them.

## 3. APIs that should intentionally differ

- Reject iOS/APNS options instead of accepting and ignoring them.
- Do not expose SDK shutdown, installation/user deletion, arbitrary token injection, or background
  Dart message execution because no equivalent is established.
- Represent Chat as native UI integration with verified component commands and listeners. Preserve the
  distinction between component-scoped sending/threads/attachments and an unavailable complete
  headless history or message repository.
- Separate server registration from Android notification permission/settings.
- Make Android resource-based notification and Chat theme configuration host-owned rather than
  pretending that resource identifiers are portable Dart values.

## 4. Implementation order

1. Core initialization, lifecycle state, common result/error mapping.
2. Installation registration and cached/fetched Installation model.
3. User fetch/save and personalization lifecycle.
4. Foreground native events, tap replay, and Message mapping.
5. Inbox fetch/filter/seen flows.
6. Chat availability, native UI presentation, contextual data and unread count.

This order establishes lifecycle, serializers and error behavior before UI-heavy modules.

## 5. MethodChannel responsibilities

A later MethodChannel should carry bounded request/response operations only: initialization,
registration mutation, User/Installation reads and updates, counter operations, Inbox fetch/seen,
and supported Chat commands. The handler should validate arguments, enforce initialization and
Activity preconditions, call native asynchronous APIs, reply exactly once, and return a common
structured error. It should not carry ongoing listeners, raw Android objects, resource objects,
throwables, or speculative future method names.

## 6. EventChannel responsibilities

A later EventChannel should carry only verified unsolicited events: received messages, notification
and action taps, registration/user/installation changes, personalization lifecycle, and the limited
Chat listener callbacks available in 8.14.0. Use one versioned event envelope with type, payload and
optional timestamp; define its concrete event names only during implementation approval. Buffer only
launch-critical notification taps, with a bounded single-consumer policy. Register native listeners
on listen, unregister on cancel/engine detach, and never retain an Activity.

## 7. Native Android module boundaries

- **Core:** SDK construction, state machine, application context and common callback/error adapter.
- **Push/events:** registration, counters, EventBus subscription and cold-start tap handoff.
- **User:** identity/attributes conversion and personalization sequencing.
- **Installation:** read/write allow-list and device-managed metadata conversion.
- **Inbox:** `MobileInbox` operations, filters and Inbox serializers.
- **Chat:** chat singleton, listener, main-thread Activity/Fragment presentation and teardown.
- **Platform bridge:** channel decoding/encoding and Flutter engine/Activity attachment only.

Keep these as focused implementation units; do not add repository/service interfaces unless testing
or lifecycle ownership demonstrates a concrete need.

## 8. Model mapping strategy

Use explicit field-by-field mappers and a documented wire schema. Never rely on reflection, Java
serialization, enum ordinals, `toString()`, or Android `Bundle` leakage. Encode dates consistently
as UTC ISO-8601 strings or epoch milliseconds, use stable string enum values with an unknown
fallback, preserve absent-versus-null patch semantics, and restrict custom attributes to the value
kinds supported by the native SDK. Define read models separately from writable patches for
Installation and User data so SDK-owned fields cannot be mutated.

## 9. Error mapping strategy

Use one Dart exception family with stable code, human-readable message, module/operation, sanitized
native code and optional retryability/details. Recommended categories are invalid argument, not
initialized, already initialized, activity unavailable, network, server, authentication,
configuration, HMS unavailable, unsupported, and native error. Convert every SDK callback failure
and channel-boundary exception; never expose a Java stack trace, application code, push token or
personal data. Preserve module-specific details without creating unrelated exception hierarchies.

## 10. Chat architecture concerns

Chat remains native-UI-first, but Huawei 8.14.0 is not limited to a full-screen Activity. The
recommended first embedded architecture to evaluate is:

```text
Flutter widget tree (Scaffold, AppBar, controls)
    ↓
Android PlatformView
    ↓
InAppChatView
```

This keeps the Flutter `AppBar`, navigation presentation, and business controls in Flutter while
embedding the reusable Infobip Chat UI. `InAppChatView` should be evaluated before Fragment hosting
because a View-backed PlatformView may avoid a nested FragmentManager and Fragment transaction/state
restoration layer. This is a recommendation for the later design phase, not an implementation claim:
the adapter must first verify and correctly supply the lifecycle required by
`InAppChatView.init(Lifecycle)`, including recreation, attachment/detachment, disposal, and the
Flutter engine versus Activity lifecycle boundary.

`InAppChatFragment` remains a valid alternative. Its verified `withToolbar` option can remove the
native toolbar so Flutter retains the app bar, and `withInput` permits a custom input. The native
input should remain enabled by default. The Fragment may provide more conventional Android lifecycle
and state restoration, but embedding it inside a PlatformView requires a compatible
FragmentActivity/FragmentManager, a stable container ID, transaction timing, saved-state handling,
and coordinated disposal. It can therefore be preferable only after those host constraints are
weighed against the View lifecycle adapter.

For either component, forward Flutter/system back and toolbar actions through
`navigateBackOrCloseChat()` and `showThreadList()` rather than blindly popping the Flutter route.
Component commands such as `send(MessagePayload)`, thread operations, contextual data, language, and
widget theme require deliberate model conversion and main-thread dispatch. Component event listeners
can later feed selected Flutter events, but `onChatRawMessageReceived` is not a complete typed message
history stream. Attachment support likewise distinguishes native UI handling and preview callbacks
from a fully custom Flutter upload/download workflow.

The eventual implementation must avoid retaining Context/Activity references, detach listeners with
the owning engine/view, coordinate keyboard and accessibility behavior, survive Activity recreation,
and prevent concurrent presentation. Personalization changes affect the SDK-managed Chat session.
Unread count is asynchronous, and unavailable/offline must not be represented as zero. The native
Activity remains a supported fallback for simple full-screen presentation; no public Flutter Chat
API, PlatformView, channel method, event, or model is introduced by this Phase 2 decision.

## 11. Inbox architecture concerns

Require successful core initialization and personalization state appropriate to the SDK before Inbox
operations. Translate filters explicitly, validate date ranges and pagination, and preserve server
counts rather than deriving them from a page. Mark-seen should be server-confirmed before updating
Dart state. Message-received can invalidate a client cache but is not proof that a synchronized Inbox
page changed. Do not promise offline authority or a continuous Inbox stream.

## 12. Huawei host-application requirements

The host application must include Huawei Mobile Services/Push Kit configuration appropriate to its
build (including Huawei project/app configuration), use a Huawei-capable device/environment, allow
manifest merging for SDK services/receivers, and provide valid Infobip/Huawei application
credentials outside source control. Android 13+ notification permission remains host/UI policy and
is distinct from Infobip registration. Notification icons, channels, colors and Chat themes are
Android resources. Chat presentation requires an Activity and compatible theme; background services
must follow current Android execution rules. Applications should test token refresh, process death,
cold/warm notification taps, Activity recreation, notification permission denial, HMS unavailable,
and network recovery on real Huawei devices.
