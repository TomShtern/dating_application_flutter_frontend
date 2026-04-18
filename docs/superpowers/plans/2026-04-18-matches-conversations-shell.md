# Matches Conversations Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the signed-in app flow with a lightweight mobile navigation shell plus working matches and conversations list screens backed by the current backend contract.

**Architecture:** Replace the direct post-login browse handoff with a small signed-in shell that owns the selected-user session and bottom navigation state. Add thin models and API methods for matches and conversations, Riverpod providers for those lists, and two list screens that stay honest about the backend’s thin DTOs while providing refresh, empty, error, and retry states.

**Tech Stack:** Flutter, Dart, Material 3, flutter_riverpod, dio, shared_preferences, flutter_test

---

## File map

### Modify
- `lib/features/home/app_home_screen.dart` — route selected users into a signed-in shell instead of directly into browse
- `lib/api/api_client.dart` — add matches and conversations fetch methods
- `lib/api/api_endpoints.dart` — add endpoint helpers for matches and conversations
- `test/widget_test.dart` — update signed-in expectations to include the navigation shell

### Create
- `lib/models/match_summary.dart`
- `lib/models/matches_response.dart`
- `lib/models/conversation_summary.dart`
- `lib/features/home/signed_in_shell.dart`
- `lib/features/matches/matches_provider.dart`
- `lib/features/matches/matches_screen.dart`
- `lib/features/chat/conversations_provider.dart`
- `lib/features/chat/conversations_screen.dart`
- `test/models/matches_response_test.dart`
- `test/models/conversation_summary_test.dart`
- `test/features/matches/matches_provider_test.dart`

## Task 1: Add failing tests for the shell and new data models
- [x] Add a widget test proving a persisted user sees a navigation shell with browse, matches, and chat/conversations destinations
- [x] Add model tests proving the matches and conversations payloads parse the documented backend shapes
- [x] Add a provider test proving matches refresh from the API client

## Task 2: Add matches and conversations models plus API methods
- [x] Add serializable models for match summary, matches response, and conversation summary
- [x] Extend the API client with `getMatches` and `getConversations`
- [x] Keep user-scoped reads aligned with the centralized `X-User-Id` behavior

## Task 3: Add the signed-in shell and list providers
- [x] Create a bottom-navigation shell for selected users with Browse, Matches, and Chats destinations
- [x] Add Riverpod providers for matches and conversations lists
- [x] Keep browse as the first/default destination

## Task 4: Build matches and conversations screens
- [x] Build a matches list screen with loading, empty, retry, and refresh states
- [x] Build a conversations list screen with loading, empty, retry, and refresh states
- [x] Surface the current DTO fields honestly without inventing avatars or message previews
- [x] Provide a clear “chat screen comes next” affordance where appropriate without faking a completed chat flow

## Task 5: Verify the slice
- [x] Run focused tests for the shell, models, and providers
- [x] Run the full Flutter test suite
- [x] Run `flutter analyze`
- [x] Launch the app on Windows using `.env`

## Notes
- The backend conversation list DTO is intentionally thin; do not invent avatar URLs or preview text.
- The goal of this slice is list navigation and visibility, not yet full message-thread rendering.
- Keep the shell modest and easy to replace if the navigation needs evolve later.
