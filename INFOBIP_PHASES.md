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

- [x] Implement approved push registration and SDK-owned token handling
- [x] Implement approved notification payload and action handling
- [x] Expose approved foreground, opened, action, and registration events

Background Dart isolate delivery is unsupported by this wrapper and is not claimed as a completed event capability.

## Phase 5 - User Management

- [ ] Implement approved user registration and profile APIs
- [ ] Implement approved user identity and attribute handling

## Phase 6 - Installation Management

- [ ] Implement approved installation retrieval and update APIs
- [ ] Implement approved installation attributes and push status handling

## Phase 7 - Inbox

- [ ] Implement approved Inbox APIs
- [ ] Implement Inbox data mapping and events

## Phase 8 - Chat

- [ ] Implement approved Chat APIs
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
