# Phase 9 SDK hardening audit

This is the internal inventory used to audit the package against the official Flutter surface and
the Huawei SDK 8.14.0 dependency. Arbitrary maps remain public only for native custom attributes
and notification/Inbox custom payload, whose semantics are data rather than SDK entities.

## Public API inventory

| Public API | Module | Dart type | Native API / channel | Error and null contract | Status/action |
| --- | --- | --- | --- | --- | --- |
| `InfobipMobileMessagingHuawei.initialize` | Core | `Future<void>` | `MobileMessaging.Builder`; `initialize` | ArgumentError before channel; stable PlatformException codes | Stable; audited idempotence |
| `getUser`, `fetchUser`, `saveUser` | User | `Future<User>` | `MobileMessaging.user/fetchUser/saveUser`; matching methods | Never nullable; failures throw | Stable; codecs audited |
| `personalize`, `depersonalize` | User | `Future<User>`, `Future<void>` | Huawei personalization APIs | Never nullable; failures throw | Stable; identity remains separate |
| `getInstallation`, `fetchInstallation`, `saveInstallation` | Installation | `Future<Installation>` | Huawei installation APIs | Never nullable; failures throw | Stable; writable projection audited |
| `fetchInbox`, `setInboxMessagesSeen` | Inbox | `Future<Inbox>`, `Future<void>` | `MobileInbox`; matching methods | Empty messages means no results; failures throw | Stable; identifiers/JWT validated |
| `notifications.onMessageReceived` | Notifications | `Stream<PushMessage>` | `MESSAGE_RECEIVED` event | Malformed/foreign events ignored | Stable; decoder hardened |
| `notifications.onNotificationTapped` | Notifications | `Stream<PushMessage>` | `NOTIFICATION_TAPPED` event | One pending tap replays once | Stable; cold-start preserved |
| `notifications.onNotificationActionTapped` | Notifications | `Stream<NotificationActionEvent>` | `ACTION_TAPPED` event | Nullable action ID; malformed event ignored | Stable |
| `notifications.onRegistrationUpdated` | Installation events | `Stream<Installation>` | `REGISTRATION_UPDATED` event | Malformed event ignored | Stable |
| `notifications.onInstallationUpdated` | Installation events | `Stream<Installation>` | `INSTALLATION_UPDATED` event | Malformed event ignored | Stable |
| `chat.getUnreadMessageCount` | Global Chat | `Future<int>` | `MobileChat.unreadMessagesCounter`; `getChatUnreadMessageCount` | Non-negative; failures throw, never become zero | Stable |
| `chat.onUnreadMessageCounterUpdated` | Global Chat | `Stream<int>` | `InAppChatEventsListener` | Malformed/negative/foreign events ignored | Stable |
| `InfobipHuaweiChatView` and `onError` | Embedded Chat | Widget / callback | view-scoped PlatformView channel | Typed lifecycle error with unknown fallback | Stable |
| `InfobipHuaweiChatController.isAttached` | Embedded Chat | `bool` | Local view binding | False when detached | Stable |
| `navigateBackOrCloseChat` | Embedded Chat | `Future<bool>` | `InAppChatView.navigateBackOrCloseChat` | Detached means false; malformed attached result throws | Hardened boolean decoding |
| `send` | Embedded Chat | `Future<void>` | `InAppChatView.send(MessagePayload)` | Empty text rejected; native failures throw | Stable |
| `sendContextualData` | Embedded Chat | `Future<void>` | `InAppChatView.sendContextualData(String)` | Opaque non-empty string; failures throw | Stable |
| `setLanguage`, `getLanguage` | Embedded Chat | `Future<void>`, `Future<String>` | `LivechatWidgetLanguage` conversion | Unsupported input fails; null native result fails | Stable; enum mapping audited |
| `setWidgetTheme`, `getWidgetTheme` | Embedded Chat | `Future<void>`, `Future<String?>` | Huawei string theme APIs | Null means no explicit active theme | Corrected native nullability |

## Public models and enums

| Type | Semantics reviewed | Result |
| --- | --- | --- |
| `User`, `UserIdentity`, `UserAttributes` | Immutable nullable patch fields, date-only birthday, custom values | Coherent |
| `Gender` | Stable string wire values; unknown native fallback is read-only | Coherent |
| `Installation` | Immutable snapshot; only primary-device and custom attributes are writable | Coherent |
| `InboxFilterOptions` | UTC bounds, topic validation, positive integral limit | Native fractional truncation fixed |
| `Inbox`, `InboxMessage` | Non-negative counters, required ID/booleans, UTC timestamp, recursive payload | Boolean decoding hardened |
| `PushMessage`, `NotificationActionEvent` | Shared model across receive/tap/action paths, recursive payload | Unsafe casts/stringified keys removed |
| `InfobipHuaweiChatError`, `InfobipHuaweiChatErrorCode` | Typed lifecycle failure, future-code fallback | Coherent |
| `InfobipHuaweiChatMessagePayload` | Outgoing text only, immutable, validated | Coherent |

## Wire and error contracts

Absolute timestamps use UTC ISO-8601 strings. User birthdays use date-only `YYYY-MM-DD`. The native
Inbox timestamp is explicitly converted from Huawei's epoch-millisecond field; no magnitude-based
unit inference is used. Event envelope timestamps are epoch milliseconds and remain internal.
Custom-attribute `DateTime` values use tagged UTC ISO-8601 values so ordinary strings are not
misidentified as dates.

| Error code | Meaning | Modules | Public | Recoverable |
| --- | --- | --- | --- | --- |
| `invalid_argument` | Invalid channel input | All | Yes | Yes, change input |
| `not_initialized` | Core initialization required | User, Installation, Inbox, Chat | Yes | Yes, initialize |
| `already_initialized` | Conflicting application code | Core | Yes | No for that engine |
| `initialization_failed` | SDK build callback failed | Core | Yes | Retry same code |
| `activity_unavailable` | Embedded view has no Activity | Chat view | Typed callback | Usually lifecycle-dependent |
| `chat_unavailable` | Chat/view unavailable | Chat | Yes | Possibly |
| `native_error` | Local native boundary failure | All | Yes | Depends on operation |
| `user_fetch_failed`, `user_save_failed` | User server operation failed | User | Yes | Usually |
| `personalization_failed`, `depersonalization_failed` | Personalization operation failed | User | Yes | Usually |
| `installation_fetch_failed`, `installation_save_failed` | Installation server operation failed | Installation | Yes | Usually |
| `inbox_fetch_failed`, `inbox_update_failed` | Inbox server operation failed | Inbox | Yes | Usually |

All codes use snake_case. Non-Chat APIs retain their established PlatformException behavior; Chat
view lifecycle errors retain their typed error. Native error details never contain request values,
JWTs, application codes, message content, contextual data, tokens, or stack traces.

## Cross-module findings

- Every native object is projected into StandardMessageCodec-compatible scalar/list/map values.
- Every plugin and view handler returns success, error, or notImplemented exactly once; asynchronous
  completions are posted to the main thread.
- One native event listener set exists per engine. Event type filtering keeps notification and Chat
  streams isolated. Cold-start stores only the latest tap and consumes it once.
- Application context is retained for non-UI SDK managers; Activity is instance-scoped, cleared on
  detach/configuration changes, and only supplied when constructing a PlatformView.
- No sensitive-value logging exists. Unsupported custom-attribute objects fail rather than being
  stringified. Notification payload maps now reject invalid nested keys rather than stringifying.
- No obsolete registration methods, native SDK object leakage, dead bridge method, or duplicate
  mapper suitable for safe removal was found.
- Thread APIs, programmatic attachments, raw Chat messages, additional Chat events, iOS, and FCM
  remain intentionally outside the approved scope.

## Breaking corrections before first release

| Old API/behavior | New API/behavior | Reason | Migration |
| --- | --- | --- | --- |
| `getWidgetTheme(): Future<String>` converted a native null into `native_error` | `getWidgetTheme(): Future<String?>` preserves null | Huawei can represent no explicit active theme | Handle null as the default/unset theme |
| Attached Chat navigation converted a missing native result to `false` | A missing/non-boolean result throws `FormatException` | False means a genuine native navigation decision, not bridge failure | No change for valid native results; treat malformed bridge data as failure |
| Public `PushMessage.fromMap` exposed the platform wire map and accepted malformed fields | Wire decoding is internal and rejects malformed stable fields and recursive payload values | Prevent an internal wire format becoming permanent public API or silently corrupting values | Construct `PushMessage` with its typed constructor; platform decoding was not an intended consumer API |
