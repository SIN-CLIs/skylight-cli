# agents.md — Protocols For Any Agent Working In This Repo

> **TL;DR:** `AGENTS.md` at the repo root is the **entry point** (read-once orientation). This file is the **operating manual** (consult while working). If you only have time for one, read `AGENTS.md`. If you are about to write code, read this one too.

---

## Agent Roles

This repo is touched by three kinds of agents. Identify yourself before you act.

### Role A — Builder Agent
You are writing or modifying Swift code in `Sources/`.

**Required reading before first edit:**
1. `AGENTS.md` (root)
2. `docs/architecture.md`
3. `docs/brain.md` (skim decision log to confirm your change isn't already-rejected)

**Required actions when you finish:**
1. `swift build` succeeds (verified locally OR in CI).
2. Update `docs/handoff.md` "What Is Done" / "What Is NOT Done."
3. If you made a non-obvious choice, append `D-NNN` to `docs/brain.md`.
4. Append a session log under `docs/sessions/session-NN.md`.

### Role B — Operator Agent
You are running the binary against a real macOS, debugging behavior.

**Required reading before first command:**
1. `README.md` (usage)
2. `docs/recovery-mode.md` (skim symptom headers so you recognize them later)

**Required actions when something goes wrong:**
1. Match symptom in `docs/recovery-mode.md`.
2. If no match: write the failure into `docs/sessions/session-NN.md` under "Stuck" before touching code.

### Role C — Orchestrator Agent (lives in OpenCode, not here)
You are the brain calling this CLI as a subprocess.

**Required reading before first call:**
1. `AGENTS.md` "Output Contract" + "Exit Codes" sections.
2. `docs/stealth-triade.md` to understand siblings.

**You MUST:**
- Treat stdout as strict JSON; do not log stdout as text.
- Branch on `status` (`"ok"` | `"error"`) AND on exit code, in that order.
- On exit code 4 (I/O / click rejection): inspect `used_fallback` field. If `true`, the visible cursor moved — alert the operator that stealth was compromised for that step.
- On exit code 3 (not found): re-screenshot before retrying. The window state may have changed.
- Never call this CLI more than once concurrently against the same PID.

---

## Conversation Protocol With The Operator

The human operating this system speaks German and prefers concise responses. Specifically:

- **Do** answer in the language the operator wrote in.
- **Do** be direct: "I will do X" / "Here is the result" — not "I might consider potentially..."
- **Do** flag security issues (leaked tokens, credentials in chat) immediately, before continuing the task.
- **Don't** use emojis in code, commits, or doc files.
- **Don't** add motivational filler ("Great question!", "Sure thing!").
- **Don't** ask permission for read-only inspection. Ask permission for destructive ops.

---

## When To Ask Vs. When To Decide

**Decide silently and proceed:**
- Naming a new internal helper function.
- Choosing between two equivalent stdlib APIs.
- Formatting / whitespace.
- Adding a JSON field that does not break existing consumers (additive change).

**Decide and append `D-NNN` to `docs/brain.md`:**
- Choosing between two architecturally meaningful approaches (e.g., dlopen vs static link).
- Bumping a system requirement (macOS version, Swift version).
- Adding a new fallback path or a new exit code.

**Stop and ask the operator:**
- Bumping a major version / making a JSON-shape breaking change.
- Adding a new external dependency (violates D-002).
- Adding a network call (violates D-011).
- Adding a runtime side effect (file in `~`, daemon, login item).
- Anything that changes the security model.

---

## Code Style

- **Swift 5.7+ syntax.** No `async let` cleverness, no result builders. Plain functions and structs.
- **No force-unwraps in production paths.** `guard let` or `try` everywhere. Force-unwrap only in test-only or constant-known cases (e.g., regex literal that you wrote five lines above).
- **One file per concern.** Don't add a 7th type to `Utils.swift`; create a new file.
- **Doc comments are for non-obvious choices.** Don't doc-comment getters. Do doc-comment "why this 20px constant" — that is the kind of context that gets lost.
- **JSON keys are `snake_case`.** Operator parsers expect this; do not switch to camelCase mid-stream.

---

## Commit Message Convention

```
<type>: <imperative subject, <=72 chars>

<body, optional, wrap at 80>

<trailers>
```

Types we use:
- `feat` — new subcommand, new flag, new module
- `fix` — bug fix, contract preserved
- `refactor` — no behavior change
- `docs` — only files in `docs/`, `AGENTS.md`, `README.md`
- `chore` — build, gitignore, CI

Required trailer when an LLM agent is the author:
```
Co-authored-by: v0[bot] <v0[bot]@users.noreply.github.com>
```

Do not write `BREAKING CHANGE:` casually. If you wrote it, you must also bump the major in `SKYLIGHT_VERSION` in `main.swift`.

---

## How To Add A New Subcommand (Recipe)

You'll do this often. Follow this exact sequence:

1. **Decide the JSON shape first.** Sketch the success and error JSON in `docs/architecture.md` "Module-Level View" (or in a comment on your PR). Think about what the orchestrator needs.
2. **Add a new static function in `CLI.swift`.** Mirror the structure of an existing one (e.g., `getWindowState` is the simplest template).
3. **Wire it into `main.swift`.** Add the case to the dispatch switch. Add the case to the help text.
4. **Update `AGENTS.md`** "Output Contract" section if the JSON shape introduces new top-level fields.
5. **Update `README.md`** with a usage example.
6. **Update `docs/handoff.md`** "What Is Done" list.
7. **Build.** Smoke-test if possible.
8. **Commit** as `feat: add <name> subcommand` with the JSON shape in the commit body.

---

## How To Read A Failing Run

```
[exit code]   [stdout JSON]              what to do
─────────────────────────────────────────────────────────────────
0             {"status":"ok",...}        success
0             not valid JSON             BUG: something printed to stdout, fix the leak
2             {"code":"bad_args",...}    your call site is wrong; do not retry
3             {"code":"window_…",...}    re-screenshot, retry once
3             {"code":"element_…",...}   re-screenshot, re-walk AX, retry once
4             {"code":"io_error",...}    disk full / perms; do NOT retry
4             {"code":"click_failed",...} SkyLight rejected; check used_fallback
5             {"code":"timeout",...}     re-plan; the page never reached expected state
1             {"code":"internal_…",...}  bug, file an issue, do NOT retry
```

---

## What To Do If You Encounter Code That Looks Wrong

Before "fixing" it:

1. **`git log -p <file>`** to see the history of that line.
2. **`git grep -n <commit-msg-keyword>`** to find related commits.
3. **Check `docs/brain.md`** decision log for a `D-NNN` covering this choice.
4. **Check `docs/recovery-mode.md`** for a postmortem mentioning this code.
5. If after all of the above the code still looks wrong: open a session log entry, document your reasoning, and only THEN change it.

90% of "wrong-looking" code in this repo has a reason. The 10% that doesn't is also worth fixing — but only after you confirm.

---

## Final Reminders

- This is a **hand**, not a brain. Resist scope creep.
- One JSON object per invocation. Stdout is sacred.
- The orchestrator (`OpenCode`) is the only allowed consumer pattern; design for that consumer.
- When in doubt: search docs first, ask operator second, write code third.
