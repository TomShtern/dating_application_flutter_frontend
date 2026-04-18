# Health Browse Like Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the Flutter foundation so the app can show backend health, route a selected user into discovery, render browse candidates, and perform like/pass actions against the real backend contract.

**Architecture:** Keep the selected user as the local session anchor and add a small app-home layer that branches between the dev user picker and a new browse screen. Add thin read/write models for health and browse responses, extend the API client with health/browse/like/pass calls, and keep orchestration in Riverpod providers so widgets remain declarative.

**Tech Stack:** Flutter, Dart, Material 3, flutter_riverpod, dio, shared_preferences, flutter_test

---

## File map

### Modify
- `lib/app/app.dart` — route through a session-aware home instead of always showing the picker
- `lib/api/api_client.dart` — add health, browse, like, and pass requests
- `lib/api/api_endpoints.dart` — add like/pass endpoint helpers
- `lib/features/auth/dev_user_picker_screen.dart` — hand control back to the app shell once a user is selected
- `test/widget_test.dart` — update root-app expectation for the new app home behavior

### Create
- `lib/models/health_status.dart`
- `lib/models/browse_candidate.dart`
- `lib/models/daily_pick.dart`
- `lib/models/browse_response.dart`
- `lib/models/like_result.dart`
- `lib/features/home/app_home_screen.dart`
- `lib/features/browse/browse_provider.dart`
- `lib/features/browse/browse_screen.dart`
- `test/models/browse_response_test.dart`
- `test/features/browse/browse_provider_test.dart`

## Task 1: Add failing tests for the new root flow
- [x] Add a widget test proving the app routes to browse when a selected user is already persisted
- [x] Add a model test proving the browse response parses the documented backend shape
- [x] Add a provider test proving a like or pass action refreshes browse data

## Task 2: Add models and API methods
- [x] Add small serializable models for health, browse candidates, daily pick, browse response, and like results
- [x] Extend the API client with `getHealth`, `getBrowse`, `likeUser`, and `passUser`
- [x] Keep user-scoped mutations aligned with the current `X-User-Id` contract

## Task 3: Add health-aware app home and browse providers
- [x] Create a session-aware app home that chooses picker vs browse based on the persisted selected user
- [x] Add a backend health provider so the UI can show whether the server is reachable
- [x] Add browse providers/controllers that fetch candidates and refresh after like/pass

## Task 4: Build the browse screen
- [x] Render the selected user context and backend health status
- [x] Render daily pick if present and candidate cards for the browse list
- [x] Add explicit Like and Pass buttons with optimistic-feeling but server-sourced refresh behavior
- [x] Show clean loading, empty, conflict, and retry states
- [x] Provide a way to switch user and return to the picker

## Task 5: Verify the slice
- [x] Run focused Flutter tests for the new models/providers/widgets
- [x] Run `flutter analyze`
- [x] Launch the app on the currently available Windows target using `.env`

## Notes
- The backend browse DTO is intentionally thin; the first browse UI should not assume photos or bios exist.
- `GET /api/health` does not require the shared secret, but browse/like/pass do.
- The Android SDK setup can continue separately; this slice should still verify on Windows now and be ready for Android once the SDK is installed.
