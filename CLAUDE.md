@AGENTS.md

## Claude Code specifics

Everything durable about this repo lives in `AGENTS.md` (imported above), so
Claude Code and Codex read one source. Only Claude-specific notes belong below.

- **Subsystem detail loads itself.** The files in `.claude/rules/` are
  path-scoped — Claude Code pulls in `api.md`, `state-and-guards.md`,
  `ui-design.md`, `visual-review.md` or `testing.md` automatically when you touch
  a matching file. Don't read them pre-emptively "for context"; that spends the
  context they were moved out of `AGENTS.md` to save.
- **Do not enumerate what the repo already lists.** Dependency versions,
  endpoints and shared widgets are read from `pubspec.lock`,
  `lib/api/api_endpoints.dart` and `lib/shared/widgets/`. Prose copies of those
  three drifted before and stated things that were false. If you find yourself
  writing such a list into a doc, write the path instead.
- **Frontend work defaults to no new tests.** This is the rule most often broken
  here — see the testing policy in `AGENTS.md`. Use the screenshot workflow for
  UI quality, not widget assertions.
- **Find the design spec before redesigning any UI.** Check
  `screen-transform-prompts/prompt-<screen>.md` and `docs/design-language.md`
  first. Treat a screenshot complaint as "where did we drift from the spec",
  not "abandon the spec".
