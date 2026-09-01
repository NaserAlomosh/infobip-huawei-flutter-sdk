# API Compatibility

## Scope and method

This matrix is the Phase 2 design baseline for matching the public Dart surface of the official
`infobip_mobilemessaging` Flutter plugin to **Infobip Mobile Messaging Huawei Android SDK
8.14.0**. It is not a channel contract and does not declare APIs for this package.

The comparison uses the official Flutter repository's exported Dart libraries and Android bridge
(`lib/`, `android/src/main/`) and the Huawei SDK's `8.14.0` sources/modules (`mobile-messaging-sdk`,
`mobile-messaging-inbox`, and `mobile-messaging-chat`). A name on the current Huawei main branch
was not treated as evidence unless it is present in the `8.14.0` release. Overloads and callback
parameters are shortened in tables, but class and method names are retained. The Gradle coordinates
used to establish the release boundary are recorded in this repository's `android/build.gradle.kts`.

Statuses have these precise meanings:

- **Supported** — 8.14.0 has an API with effectively equivalent behavior.
- **Requires Adaptation** — the capability exists, but needs conversion, lifecycle/UI handling,
  event transformation, multiple calls, or a Flutter abstraction.
- **Unsupported** — 8.14.0 has no equivalent capability.
- **Under Investigation** — evidence is insufficient; no implementation should be approved yet.

> “Official Flutter API” denotes the public capability, not a proposed API for this package.
> Event transport recommendations describe feasibility only; no event or channel name is declared.

## Core / SDK lifecycle

| Official Flutter API | Huawei 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| `MobileMessaging.initialize(...)` | `MobileMessaging.Builder(Context).withApplicationCode(String).build()` | Requires Adaptation | Builder completion is asynchronous through `MobileMessaging.ResultListener`; Flutter must own one application-scoped instance and complete a Dart future. Huawei source: `mobile-messaging-sdk/src/main/java/org/infobip/mobile/messaging/MobileMessaging.java`. |
| Application code | `MobileMessaging.Builder.withApplicationCode(String)` | Supported | Same Infobip application-code concept; validate non-empty value before crossing the channel. |
| Android notification configuration supplied at initialization | `MobileMessaging.Builder.withDisplayNotification(...)` and `NotificationSettings`/manifest metadata | Requires Adaptation | Flutter configuration fields do not map one-to-one; icon, color, channel and intent handling are Android resources/settings. |
| iOS initialization options | None | Unsupported | This repository and the Huawei artifact are Android/HMS only. Do not silently accept APNS categories, provisional authorization, app-group, or notification-service-extension options. |
| Automatic Android lifecycle integration | SDK manifest components plus `Application.ActivityLifecycleCallbacks` used by SDK | Requires Adaptation | Plugin must initialize with `applicationContext`; UI operations still require an attached `Activity`. Host manifest merging remains necessary. |
| Read initialized SDK instance/state | `MobileMessaging.getInstance(Context)` | Requires Adaptation | Native singleton access exists, but there is no equivalent rich Flutter lifecycle-state object; wrapper must track initialization completion/failure. |
| Repeated initialization | `MobileMessaging.Builder.build()` / singleton instance | Requires Adaptation | 8.14.0 does not define a Flutter-style idempotent future. Serialize concurrent calls and reject conflicting application codes rather than rebuilding unpredictably. |
| Debug/logging option | `MobileMessaging.Builder.withLogging()` and SDK log configuration | Requires Adaptation | Native logging is configured during build; Flutter boolean/config conversion is required and must not expose secrets. |
| Shutdown/dispose SDK | No public `shutdown()` equivalent in 8.14.0 | Unsupported | Detaching a Flutter engine is not an SDK reset. Do not invent teardown semantics. |
| Reset/depersonalize data | `MobileMessaging.depersonalize(...)` | Requires Adaptation | This resets identity/profile data, not the SDK singleton; expose only as user lifecycle behavior. |
| Android-only platform configuration | Builder/manifest/resource settings | Requires Adaptation | Keep Huawei-only knobs in a clearly Android-specific configuration section rather than pretending cross-platform parity. |

## Push notifications

| Official Flutter API/capability | Huawei 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| Enable/disable push registration | `MobileMessaging.setRegistration(boolean, ResultListener<Installation>)` | Supported | Equivalent server-side installation registration switch. Source: `MobileMessaging.java`. |
| Query push registration | `MobileMessaging.getInstallation()` → `Installation.isPushRegistrationEnabled()` | Requires Adaptation | Local installation snapshot must be serialized; fetching current server state first may be needed where freshness matters. |
| Obtain HMS push token | Huawei Push Kit integration inside SDK; `HmsMessageService`-based token flow | Requires Adaptation | Token ownership belongs to HMS/SDK. Flutter should observe the resulting registration event rather than call FCM APIs. |
| Supply arbitrary push token | No public general-purpose Flutter token setter equivalent | Unsupported | Do not introduce a token injection API unless a public 8.14.0 Huawei method is subsequently evidenced. |
| Token refresh | SDK HMS service updates installation/token | Requires Adaptation | Background refresh is native. Surface completion through transformed registration/installation events; it is not a synchronous Dart call. |
| Foreground message delivery | `Event.MESSAGE_RECEIVED` carrying `Message` | Requires Adaptation | Subscribe through SDK `EventBus`; convert `Message` and deliver only while an engine/event subscriber exists. |
| Background message delivery to Dart isolate | Native HMS receiver/service and SDK processing | Unsupported | 8.14.0 processes messages natively but supplies no Flutter background-isolate dispatcher equivalent. Native display/data handling remains available. |
| Notification opened/tapped | `Event.NOTIFICATION_TAPPED` carrying `Message` | Requires Adaptation | Cache a launch tap until Flutter subscribes; Android intent/lifecycle ordering differs from iOS and warm starts. |
| Notification action tapped | `Event.ACTION_TAPPED` / action payload on `Message` | Requires Adaptation | Normalize action identifier and message; Android pending-intent delivery requires host/activity lifecycle bridging. |
| Silent/data message | `Message.isSilent()` and custom payload access | Requires Adaptation | Native SDK recognizes silent messages, but executing arbitrary Dart in a terminated process is not equivalent. Foreground delivery can map. |
| Notification payload fields | `org.infobip.mobile.messaging.Message` | Requires Adaptation | Model conversion is mandatory; see Messages. |
| Custom payload | `Message.getCustomPayload()` | Requires Adaptation | JSON-safe deep conversion is required; reject unsupported Java values rather than stringifying them silently. |
| Default notification display | SDK notification handler configured by `NotificationSettings` | Supported | Native SDK can display received push without Dart participation. |
| Notification icon/color/sound | `NotificationSettings` plus Android resources/manifest metadata | Requires Adaptation | Resource names/IDs cannot be portable Dart values without host configuration. |
| Android notification channel | `NotificationSettings` / Android channel configuration | Requires Adaptation | Channel creation/settings are Android-native and immutable in places after creation; document host ownership. |
| Badge/counter | `MobileMessaging.getMessageCounter()` and `resetMessageCounter()` | Requires Adaptation | Counter exists; launcher badge rendering remains launcher/device dependent. |
| Deep link/open URL | `Message.getDeeplink()` and notification tap | Requires Adaptation | SDK supplies the value; navigation and URI allow-listing belong to the Flutter host. |
| Push registration failure | `Event.REGISTRATION_UPDATED` result/error and `MobileMessaging.ResultListener` | Requires Adaptation | Map native error detail into stable error categories; never expose Java throwable objects. |

## Event system

The official plugin's event stream is conceptually backed by Android SDK events. The recommended
transport is shown for design purposes; names are intentionally not specified in Phase 2.

| Official Flutter event/capability | Huawei 8.14.0 source | Status | Feasible transport and payload |
| --- | --- | --- | --- |
| Message received | `Event.MESSAGE_RECEIVED`, `Message` | Requires Adaptation | EventChannel; serialize `Message`. Foreground engine only. |
| Notification tapped/opened | `Event.NOTIFICATION_TAPPED`, `Message` | Requires Adaptation | EventChannel with cold-start replay buffer. |
| Notification action tapped | `Event.ACTION_TAPPED` | Requires Adaptation | EventChannel; serialize action plus message. |
| Registration updated | `Event.REGISTRATION_UPDATED`, `Installation` | Requires Adaptation | EventChannel; token changes must be redacted from logs. |
| Installation updated | `Event.INSTALLATION_UPDATED`, `Installation` | Requires Adaptation | EventChannel; local SDK events are the authoritative native trigger. |
| User updated | `Event.USER_UPDATED`, `User` | Requires Adaptation | EventChannel; serialize nullable/typed attributes. |
| Personalized | `Event.PERSONALIZED` | Requires Adaptation | EventChannel or completion of the initiating MethodChannel call plus event broadcast. |
| Depersonalized | `Event.DEPERSONALIZED` | Requires Adaptation | Same dual completion/broadcast rule; clear cached Dart identity. |
| Error event | SDK operation callbacks carry `MobileMessagingError` | Requires Adaptation | MethodChannel error for requested operations; EventChannel only for unsolicited asynchronous failure. |
| Token received as a standalone event | Registration/installation update, not a distinct stable Flutter-neutral event | Requires Adaptation | Derive from installation transition; do not promise every underlying HMS callback. |
| Inbox changed/new inbox message | Message received plus explicit `MobileInbox.fetchInbox(...)` | Requires Adaptation | EventChannel can signal invalidation; fetch via MethodChannel. No continuously synchronized inbox stream. |
| Chat unread count changed | `InAppChatEventsListener.onChangedUnreadMessagesCounter(int)` | Requires Adaptation | EventChannel; listener registration/removal must follow engine lifecycle. |
| Chat connection/state/error events | `InAppChatEventsListener` callbacks available in chat module | Requires Adaptation | EventChannel after converting finite states/errors; exact callback coverage is narrower than a raw web-chat event bus. |
| Arbitrary chat message-received model event | No public 8.14.0 native message stream equivalent | Unsupported | Chat UI/listener does not expose the complete conversation message model to Flutter. |
| Poll SDK state | getters plus `fetchUser`, `fetchInstallation`, `fetchInbox` | Requires Adaptation | MethodChannel polling is possible but should not replace native events. |

Native event evidence: `mobile-messaging-sdk/src/main/java/org/infobip/mobile/messaging/Event.java`
and `.../EventBus.java`; chat evidence:
`mobile-messaging-chat/src/main/java/org/infobip/mobile/messaging/chat/InAppChatEventsListener.java`.

## User management

| Official Flutter API/capability | Huawei 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| Get cached user | `MobileMessaging.getUser()` | Supported | Returns the SDK's local `User` snapshot. |
| Fetch user | `MobileMessaging.fetchUser(ResultListener<User>)` | Supported | Asynchronous server refresh maps naturally to a future. |
| Save/update user | `MobileMessaging.saveUser(User, ResultListener<User>)` | Requires Adaptation | Construct a patch-like `User`; distinguish absent fields from explicit null where native builder/model supports it. |
| Personalize/register user | `MobileMessaging.personalize(UserIdentity, UserAttributes, boolean, ResultListener<User>)` | Requires Adaptation | One official Flutter object must split into identity and attributes; `forceDepersonalize` semantics need an explicit option. |
| Depersonalize/logout | `MobileMessaging.depersonalize(ResultListener<...>)` | Supported | Native identity reset exists; it does not shut down SDK or necessarily disable push. |
| External user ID | `UserIdentity.setExternalUserId(...)` / `User.getExternalUserId()` | Supported | Same identity concept. |
| Identity by phone/email | `UserIdentity` phone/email fields | Supported | Normalize/validate using SDK constraints; do not infer identity merge policy. |
| First/last name | `UserAttributes` / `User` name properties | Supported | Direct scalar mapping. |
| Gender enum | `User.Gender` | Requires Adaptation | Convert enum names defensively and preserve unknown future values. |
| Birthday | `User`/`UserAttributes` birthday (`Date`) | Requires Adaptation | Use an unambiguous UTC/ISO-8601 contract; native value is a Java date. |
| Tags | `User.getTags()` and user update model | Requires Adaptation | Convert collection and preserve replacement/merge behavior documented by SDK. |
| Custom attributes | `User.getCustomAttributes()` / update model | Requires Adaptation | Native supported value types must be encoded explicitly; nested arbitrary JSON is not guaranteed. |
| Merge/link users | `personalize(..., forceDepersonalize, ...)` identity rules | Requires Adaptation | Capability is workflow-level, not a direct generic `mergeUsers` primitive. Surface conflict rather than auto-merging. |
| Clear individual user property | `saveUser` with supported nullable field/update semantics | Requires Adaptation | Requires deliberate null-vs-omitted encoding. |
| Delete server user | No public delete-user API | Unsupported | Depersonalization only disconnects/reset identity according to SDK semantics. |

Model source: `mobile-messaging-sdk/src/main/java/org/infobip/mobile/messaging/User.java`,
`UserIdentity.java`, and `UserAttributes.java`.

## Installation management

| Official Flutter API/capability | Huawei 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| Get cached installation | `MobileMessaging.getInstallation()` | Supported | Local snapshot. |
| Fetch installation | `MobileMessaging.fetchInstallation(ResultListener<Installation>)` | Supported | Server refresh maps to a future. |
| Save/update installation | `MobileMessaging.saveInstallation(Installation, ResultListener<Installation>)` | Requires Adaptation | Use an allow-list of writable properties; device-managed fields must be read-only in Dart. |
| Installation ID | `Installation.getInstallationId()` | Supported | SDK-owned stable installation identifier; host must not set it. |
| Push registration enabled | `Installation.isPushRegistrationEnabled()` / `setRegistration(...)` | Supported | Read property; mutate through the dedicated SDK method. |
| Push token | `Installation.getPushRegistrationId()` | Requires Adaptation | Read-only sensitive HMS-derived value. Prefer not to expose unless parity requires it; never log it. |
| Primary device | `Installation.isPrimaryDevice()` / writable installation update property | Requires Adaptation | Server conflict and identity requirements must surface through operation errors. |
| App version | `Installation.getAppVersion()` | Supported | SDK-populated metadata; read-only. |
| SDK version | `Installation.getSdkVersion()` | Supported | Read-only diagnostic metadata. |
| OS/device model/manufacturer | `Installation` device/OS properties | Supported | Read-only and may be nullable/redacted. |
| Device timezone/language | `Installation` metadata properties | Requires Adaptation | Java/Android representations need stable string conversion. |
| Custom installation attributes | `Installation.getCustomAttributes()` / `saveInstallation` | Requires Adaptation | Restrict to native supported primitive/date types and preserve patch semantics. |
| Installation updated event | `Event.INSTALLATION_UPDATED` | Requires Adaptation | EventChannel conversion. |
| Delete installation | No public delete-installation operation | Unsupported | Disabling registration is not deletion. |

Model source: `mobile-messaging-sdk/src/main/java/org/infobip/mobile/messaging/Installation.java`.

## Messages and notification models

| Official Flutter field/model | Huawei 8.14.0 native type/member | Status | Mapping notes |
| --- | --- | --- | --- |
| Message identifier | `Message.getMessageId()` | Supported | String identifier. |
| Title | `Message.getTitle()` | Supported | Nullable string. |
| Body | `Message.getBody()` | Supported | Nullable string. |
| Sound | `Message.getSound()` | Supported | Nullable Android notification sound reference. |
| Silent flag | `Message.isSilent()` | Supported | Boolean; processing constraints remain platform-specific. |
| Custom payload/data | `Message.getCustomPayload()` | Requires Adaptation | Convert recursively to channel-safe values. |
| Deep link | `Message.getDeeplink()` | Supported | String/URI-like value; host validates before navigation. |
| Received/sent timestamp | `Message` timestamp/date member | Requires Adaptation | Convert Java epoch/date to UTC ISO-8601 or epoch milliseconds consistently. |
| Notification/action category | `Message` category/action fields | Requires Adaptation | Android categories/actions are not identical to iOS notification categories. |
| Action/button | `NotificationAction`/message action metadata and `Event.ACTION_TAPPED` | Requires Adaptation | Create a Dart-neutral projection; pending intent/UI mechanics stay native. |
| Original payload | `Message` bundle/map serialization | Requires Adaptation | Do not expose Android `Bundle`; flatten only documented serializable fields. |
| Delivery/open state | No per-push mutable delivery/open state model exposed locally | Unsupported | Server analytics are not a local message property. |
| Foreground display decision | Native notification handling/configuration | Requires Adaptation | Official Flutter callback-style presentation control is not equivalent to Huawei's native handling. |
| Huawei-only metadata | `Message` internal/HMS transport fields | Requires Adaptation | Keep transport/internal keys out of the public model unless documented and stable. |

Source: `mobile-messaging-sdk/src/main/java/org/infobip/mobile/messaging/Message.java` and
notification classes under `.../notification/`.

## Inbox

| Official Flutter Inbox API/capability | Huawei Inbox 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| Fetch inbox | `MobileInbox.getInstance(Context).fetchInbox(...)` | Requires Adaptation | Callback result must become a future and models must be serialized. Source: `mobile-messaging-inbox/.../MobileInbox.java`. |
| Filter by topics | `InboxFilterOptions` topic filter | Supported | Native server-side filter exists. |
| Filter by date range | `InboxFilterOptions` date-from/date-to fields | Requires Adaptation | Convert Dart timestamps to Java dates and define inclusive boundary behavior. |
| Pagination/limit | `InboxFilterOptions` plus fetch result paging parameters | Requires Adaptation | Official Flutter continuation/page shape needs conversion to Huawei result metadata; do not fake client-only pagination. |
| Inbox total count | `Inbox.getCountTotal()` (result count member) | Supported | Map result metadata, not list length. |
| Inbox unread count | `Inbox.getCountUnread()` | Supported | Map result metadata. |
| Inbox messages | `Inbox.getMessages()` / `InboxMessage` | Requires Adaptation | Convert each native model; retain unknown custom payload. |
| Mark messages seen | `MobileInbox.setSeen(...)` | Requires Adaptation | Async callback and identifier/model collection conversion; update local UI only after success. |
| Seen/unseen state | `InboxMessage.isSeen()` | Supported | Boolean field. |
| Message details/title/body | `InboxMessage` fields | Requires Adaptation | Mostly direct, with date/custom payload/action conversion. |
| Message topics | `InboxMessage.getTopic()`/topic fields | Supported | Preserve nullable/unknown topic values. |
| Inbox configuration | Inbox SDK singleton/module configuration | Requires Adaptation | Module must be available and core initialized; configuration is not a free-standing Flutter object. |
| Inbox change listener | No dedicated continuously synchronized inbox listener | Unsupported | Use message event as invalidation hint and explicitly refetch. |
| Offline authoritative inbox | No equivalent offline database contract | Unsupported | A cached UI may be built later, but it is not SDK parity. |
| Inbox error | Inbox callback error (`MobileMessagingError`) | Requires Adaptation | Map network, authorization, validation and native errors consistently. |

Native evidence paths are under
`mobile-messaging-inbox/src/main/java/org/infobip/mobile/messaging/inbox/`, notably
`MobileInbox.java`, `Inbox.java`, `InboxMessage.java`, and `InboxFilterOptions.java`.

## Chat

Huawei Chat 8.14.0 is primarily a **native UI/web-chat integration**, not a headless Dart chat
client. That distinction prevents several superficially similar API names from being classified as
supported.

| Official Flutter Chat API/capability | Huawei Chat 8.14.0 native API | Status | Evidence and implementation notes |
| --- | --- | --- | --- |
| Initialize chat module | `MobileChat.getInstance(Context)` / chat module initialization tied to core SDK | Requires Adaptation | Core SDK must be ready first; retain application context and install listeners once per engine. |
| Check chat availability | `MobileChat` availability/configuration callback | Requires Adaptation | Network/config result is asynchronous and may change; map to a future/state rather than a compile-time flag. |
| Show/open chat | `InAppChatScreen.show(Context)` / chat activity entry point | Requires Adaptation | Requires an attached, foreground `Activity`; call on main thread and fail predictably when detached. |
| Native chat Activity UI | `InAppChatScreen` | Supported | Full native chat UI is the closest parity for `showChat`; theme/manifest behavior is host-native. |
| Embed chat in custom UI | `InAppChatFragment` / `InAppChatView` | Requires Adaptation | Flutter PlatformView/Fragment integration, lifecycle ownership and back navigation would be needed. Do not treat as a simple method call. |
| Close/hide chat | Activity/Fragment lifecycle/navigation | Requires Adaptation | Finish/pop native UI on main thread; behavior depends on presentation mode. |
| Set chat language | `MobileChat`/`InAppChat` language configuration | Requires Adaptation | Validate supported locale and define whether restart/reload is needed. |
| Chat authentication/session | SDK personalization plus chat session managed internally | Requires Adaptation | No Flutter-accessible credential/session token should be invented. User identity changes must synchronize with core personalization. |
| Restart chat connection | Chat connection/reload API on `MobileChat`/`InAppChat` | Requires Adaptation | Must observe native lifecycle and main-thread constraints. |
| Get unread count | Chat unread-message counter getter/callback | Requires Adaptation | Async/cached result maps to a future; unavailable/offline states must not collapse to zero. |
| Listen for unread count | `InAppChatEventsListener.onChangedUnreadMessagesCounter(int)` | Requires Adaptation | EventChannel is appropriate; unregister listener at engine detach. |
| Send contextual data | `MobileChat.sendContextualData(...)` | Requires Adaptation | Native validated map/string payload and callback conversion required; contextual data is not a chat message. |
| Chat connection-state listener | `InAppChatEventsListener` connection callbacks | Requires Adaptation | Expose only states actually emitted in 8.14.0; transform to a small stable enum. |
| Chat UI shown/closed lifecycle | Activity/Fragment callbacks plus chat listener coverage | Requires Adaptation | Requires host lifecycle observation; avoid retaining an Activity. |
| Receive full chat message objects | No public complete message stream/model | Unsupported | UI internally receives conversations, but 8.14.0 does not expose a Flutter-equivalent headless stream. |
| Send text message programmatically | No verified public headless `sendMessage` API | Unsupported | `sendContextualData` is not equivalent. Message composition is in native chat UI. |
| Send file/image programmatically | No verified public headless attachment API | Unsupported | Native UI may offer configured attachments; that does not establish programmatic parity. |
| Receive/download attachment model | No public headless attachment stream/model | Unsupported | Keep native UI behavior native-only. |
| Conversation/thread list/info | No public conversation repository/thread API | Unsupported | Web-chat UI/session internals are not a stable native data API. |
| Message history/pagination | No public headless history API | Unsupported | Do not scrape the UI/web layer. |
| Message delivery/read receipts | No public Flutter-equivalent model API | Unsupported | May appear inside UI but is not programmatically exposed. |
| Custom chat UI built entirely in Flutter | No low-level public chat data API | Unsupported | Only native Activity/Fragment/View integration is viable in 8.14.0. |
| Chat configuration/theme | Native chat configuration, resources and theme attributes | Requires Adaptation | Resource/theme configuration belongs to Android host; only stable runtime options should cross a channel later. |
| Chat errors | Chat callbacks / `MobileMessagingError`-style failures | Requires Adaptation | Separate unavailable, network, configuration and no-Activity errors while retaining native diagnostic details. |
| Multiple Flutter engines | Singleton chat SDK plus per-engine listener/UI ownership | Requires Adaptation | Enforce one active presentation/listener owner or provide deterministic arbitration. |

Evidence paths: `mobile-messaging-chat/src/main/java/org/infobip/mobile/messaging/chat/MobileChat.java`,
`InAppChat.java`, `InAppChatScreen.java`, `InAppChatFragment.java`, `InAppChatView.java`, and
`InAppChatEventsListener.java`. APIs appearing only in later releases must not be backported by
assumption.

## Models and enums

| Official public type/category | Huawei 8.14.0 equivalent | Status | Mapping decision |
| --- | --- | --- | --- |
| Initialization/configuration model | `MobileMessaging.Builder`, `NotificationSettings` | Requires Adaptation | Custom immutable Dart configuration eventually; split portable and Android-only fields. |
| `User`/user data | `User`, `UserIdentity`, `UserAttributes` | Requires Adaptation | One Flutter representation maps to multiple native types for personalization. |
| Gender | `User.Gender` | Requires Adaptation | Explicit wire strings and unknown fallback. |
| Installation | `Installation` | Requires Adaptation | Separate writable patch fields from read-only SDK/device fields. |
| Message/push message | `Message` | Requires Adaptation | Explicit map serializer; never Java serialization/reflection. |
| Notification action/button | Notification action metadata / `ACTION_TAPPED` | Requires Adaptation | Custom Dart projection required because platform action models differ. |
| Event envelope | `Event` plus typed payload | Requires Adaptation | Custom discriminated Dart event representation eventually; do not leak native enum ordinals. |
| Inbox | `Inbox` | Requires Adaptation | Result container with counts, messages and paging metadata. |
| Inbox message | `InboxMessage` | Requires Adaptation | Custom Dart model, date/action/custom payload conversion. |
| Inbox filter | `InboxFilterOptions` | Requires Adaptation | Validate topics, date order and paging before native call. |
| Chat message | No complete public type | Unsupported | Do not publish a model that cannot be populated. |
| Chat attachment | No complete public type | Unsupported | Native UI-only. |
| Chat connection state | Listener-specific native state/callback | Requires Adaptation | Custom finite enum with unknown fallback. |
| Native errors | `MobileMessagingError`, callback error values, HMS exceptions | Requires Adaptation | Stable Dart exception/code/details envelope. |
| iOS/APNS-specific enums/models | None | Unsupported | Huawei Android target only. |

## Error handling

| Official Flutter failure surface | Huawei 8.14.0 source | Status | Recommended later mapping |
| --- | --- | --- | --- |
| Invalid Dart arguments | Native validation/`IllegalArgumentException` | Requires Adaptation | Validate at Dart and native boundary; return a stable `invalid_argument` code. |
| Not initialized | Missing/unfinished `MobileMessaging` singleton | Requires Adaptation | Stable `not_initialized`; never allow null-pointer failure. |
| Duplicate/conflicting initialization | Builder/singleton behavior | Requires Adaptation | Stable `already_initialized` for a different application code; share in-flight equivalent calls. |
| Native SDK operation error | `MobileMessagingError` in `ResultListener` | Requires Adaptation | Preserve native code/message and operation in structured details. |
| HTTP/network error | SDK callback error/cause | Requires Adaptation | Normalize to `network`/`server`; preserve status/retryability only when supplied. |
| Authentication/application-code error | SDK callback/server error | Requires Adaptation | Normalize to `authentication` or `configuration`, without exposing credentials. |
| Unsupported device/HMS unavailable | Huawei Mobile Services/Push Kit availability errors | Requires Adaptation | Stable `hms_unavailable` with resolvable/native status where safe. |
| Permission/notification disabled | Android OS state and registration state | Requires Adaptation | Distinguish OS notification permission from Infobip registration. |
| No attached Activity | Plugin lifecycle state | Requires Adaptation | Stable `activity_unavailable`; applies to chat UI and intent-based operations. |
| Inbox error | Inbox callback error | Requires Adaptation | Same common envelope with module=`inbox`. |
| Chat unavailable/configuration error | Chat callbacks/availability state | Requires Adaptation | Same envelope with module=`chat`; do not report unavailable as unread count zero. |
| Unexpected native exception | Java/Kotlin throwable | Requires Adaptation | Catch at channel boundary, log safely, return `native_error` with sanitized details. |
| Background Dart delivery unavailable | No background isolate bridge | Unsupported | Document limitation rather than manufacturing a successful callback. |

## Compatibility totals

Counts are by table row (one independently implementable public capability per row), not by native
overload or model property.

| Status | Count |
| --- | ---: |
| Supported | 28 |
| Requires Adaptation | 105 |
| Unsupported | 22 |
| Under Investigation | 0 |
| **Total** | **155** |

The dominant gaps are iOS-only initialization, SDK shutdown, arbitrary token injection, terminated
Dart background handling, deletion APIs, continuous/offline Inbox synchronization, and headless
Chat messages, attachments, conversations, history, and receipts. These are deliberate
non-equivalences—not future channel placeholders.
