# Infobip Huawei Flutter Plugin Roadmap

This roadmap tracks the incremental development of the Flutter wrapper for the Infobip Huawei Mobile Messaging SDK. A checked item represents completed work; all unchecked feature items remain unimplemented roadmap work.

## Phase 1 - Project Setup

- [x] Create the Flutter plugin and Android module
- [x] Establish the Flutter, Dart, Kotlin, Java, and Android dependency baseline
- [x] Configure the Huawei Maven repository and Infobip Huawei SDK 8.14.0 dependency
- [x] Add MethodChannel and EventChannel infrastructure
- [x] Add project documentation and contribution guidance
- [x] Add the example application integration shell
- [x] Verify formatting, analysis, tests, and Android builds for the setup baseline

## Phase 2 - API Compatibility Analysis

This phase is analysis-only. Do not implement features or add public APIs during this phase.

- [x] Inspect the official Infobip Flutter public Dart API
- [x] Inspect the Infobip Huawei Android SDK 8.14.0 API
- [x] Compare Core APIs
- [x] Compare Push / Notification APIs
- [x] Compare User APIs
- [x] Compare Installation APIs
- [x] Compare Inbox APIs
- [x] Compare Chat APIs
- [x] Compare models and enums
- [x] Identify unsupported APIs
- [x] Identify APIs requiring adaptation
- [x] Populate `API_COMPATIBILITY.md`

## Phase 3 - Core / SDK Initialization

- [x] Implement the approved initialization and lifecycle APIs
- [x] Map initialization results and failures to Flutter
- [x] Validate initialization behavior and repeated calls

## Phase 4 - Push Notifications and Events

- [x] Preserve the SDK-owned push registration lifecycle and token handling without exposing Huawei-only controls
- [x] Implement approved notification payload and action handling
- [x] Expose approved foreground, opened, action, and registration events

Background Dart isolate delivery is unsupported by this wrapper and is not claimed as a completed event capability.

## Phase 5 - User Management

- [x] Implement approved user registration and profile APIs
- [x] Implement approved user identity and attribute handling

## Phase 6 - Installation Management

- [x] Implement approved installation retrieval and update APIs
- [x] Implement approved installation attributes and push status handling

## Phase 7 - Inbox

- [x] Implement approved Inbox APIs with explicit external user ID and optional JWT fetch
- [x] Use typed Huawei 8.14.0 Inbox APIs, filters, counters, and message mapping
- [x] Keep Huawei native Inbox events internal because official Flutter event parity is not established

## Phase 8 - Chat

- [x] Implement embedded `InAppChatView` and view-scoped back controller
- [ ] Implement remaining approved Chat APIs
- [ ] Implement Chat models, unread-count updates, and events

## Phase 9 - Models, Mappers, and Error Handling

- [ ] Add the approved Dart models and enums
- [ ] Map native values and errors into predictable Flutter types
- [ ] Handle invalid arguments, unsupported operations, and platform failures

## Phase 10 - Example Application Integration

- [ ] Integrate completed feature areas into the example application
- [ ] Demonstrate supported workflows without placeholder credentials

## Phase 11 - Testing and Device Validation

- [ ] Add Dart, platform-channel, and native Android tests
- [ ] Validate supported workflows on Huawei devices
- [ ] Validate lifecycle, background, failure, and regression scenarios

## Phase 12 - Documentation and Release Preparation

- [ ] Document supported APIs, setup, limitations, and troubleshooting
- [ ] Complete package metadata, changelog, license, and release checks
- [ ] Run final formatting, analysis, tests, build, and publish validation

## Progress Rules

- `[x]` Completed
- `[ ]` Not completed
- Do not mark planned features complete until their implementation and validation are finished.
