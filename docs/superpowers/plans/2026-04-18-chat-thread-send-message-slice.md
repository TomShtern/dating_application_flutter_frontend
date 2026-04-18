# Chat Thread Send Message Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the signed-in chat flow from a conversations list into a real conversation thread screen that loads conversation-scoped messages and sends new messages through the current backend contract.

**Architecture:** Keep the client thin. Add a `MessageDto`, extend the centralized API client with conversation-scoped message reads and writes, create a Riverpod thread provider/controller, and push from the conversations list into a dedicated thread screen with loading, empty, error, refresh, and send states. Avoid inventing avatars, typing indicators, optimistic fake messages, or any metadata the backend does not currently expose.

**Tech Stack:** Flutter, Dart, Material 3, flutter_riverpod, dio, flutter_test

---

## File map

### Modify
- `README.md` — reflect the completed chat-thread/send-message slice
- `lib/api/api_client.dart` — add message fetch and send methods
- `lib/features/chat/conversations_screen.dart` — navigate into a thread screen
- `test/api/api_headers_test.dart` — prove conversation message routes keep both auth headers
- `test/widget_test.dart` — extend the signed-in shell flow into a chat thread

### Create
- `lib/models/message_dto.dart`
- `lib/features/chat/conversation_thread_provider.dart`
- `lib/features/chat/conversation_thread_screen.dart`
- `test/models/message_dto_test.dart`
- `test/features/chat/conversation_thread_provider_test.dart`
- `test/features/chat/conversation_thread_screen_test.dart`

## Task 1: Lock the backend contract in tests
- [x] Add a model test proving the documented `MessageDto` payload parses correctly
- [x] Extend API header tests to prove conversation message routes send both `X-DatingApp-Shared-Secret` and `X-User-Id`
- [x] Add a provider test proving thread loading and post-send refresh behavior

## Task 2: Add thin message models and API methods
- [x] Add a `MessageDto` model for conversation-scoped message responses
- [x] Extend the API client with `getMessages` and `sendMessage`
- [x] Keep message requests aligned with the centralized header and selected-user rules

## Task 3: Build thread state and UI
- [x] Add a Riverpod thread provider/controller for loading, refreshing, and sending messages
- [x] Build a conversation thread screen with loading, empty, error, refresh, and send states
- [x] Distinguish outgoing vs incoming messages using the current selected user only
- [x] Prevent blank-message sends without inventing extra client-side business rules

## Task 4: Connect conversations to real threads
- [x] Replace the conversations placeholder affordance with actual thread navigation
- [x] Keep the conversation list honest about the thin backend DTO fields
- [x] Reuse the existing signed-in shell and selected-user session flow

## Task 5: Verify the slice
- [x] Run focused model, header, provider, screen, and widget tests
- [x] Run the full Flutter test suite
- [x] Run `flutter analyze`
- [x] Launch the app on Windows using `.env`

## Notes
- Message routes are conversation-scoped via `/api/conversations/{conversationId}/messages`.
- The send-message body must include `senderId`, and the header/user identity must stay aligned with the selected dev user.
- The first implementation intentionally favors server-confirmed refreshes over optimistic local-only message mutation.