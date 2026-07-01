# SynkOS Tools — Full API Reference

The MCP tools exposed by SynkOS for multi-agent orchestration.

---

## `pane_spawn`

Open a new Claude pane in the workspace grid. The pane is visible to the user.

**Signature:**
```
pane_spawn(
  providerId?: string,   // omit for default 'claude-oauth'
  model?: string,        // must be a model the provider actually exposes
  cwd?: string,         // absolute path; defaults to current workspace
  role?: string,        // e.g. synko-dev, synko-qa — loads role SKILL.md
  storyId?: string      // active story for context tier / tool budget
) → { paneId, delegationHint, contextTier, toolBudgetProfile, ... }
```

**Returns:** the new `paneId` and a `delegationHint` suggesting `pane_write_many` for parallel work and `handoff_list` after workers call `handoff_submit`.

**Critical rule:** if `providerId` is anything other than `claude-oauth`, call `pane_list_providers()` first. Provider IDs are machine-local. Passing an unknown ID returns an error.

---

## `pane_list`

List every active pane in the workspace.

**Signature:**
```
pane_list() → {
  ok: bool,
  count: number,
  panes: [{
    paneId: string,
    agent: 'claude',
    cwd: string,
    status: 'running' | ...,
    providerId?: string,
    model?: string,
    squadOrchestratorWorkerId?: string
  }]
}
```

**When to call:** before spawning, to discover existing panes you could reuse.

---

## `pane_list_providers`

List every LLM provider configured in this SynkOS install.

**Signature:**
```
pane_list_providers() → {
  ok: bool,
  count: number,
  providers: [{ id, label, type, host, models }]
}
```

**Critical rule:** call this whenever you intend to use a non-default provider.

---

## `pane_write`

Type text into one pane's terminal as if the user typed it.

**Signature:**
```
pane_write(
  paneId: string,
  text?: string,           // raw prompt (avoid >4000 chars — use handoff mode)
  mode?: "handoff",        // preferred for delegation
  task?: string,           // required when mode=handoff
  storyId?: string,
  acceptanceCriteria?: string[],
  fileList?: string[],
  handoffPath?: string,
  submit?: boolean         // default true
) → { ok: bool, mode, charCount }
```

**Briefing principle:** the target pane has no memory of this conversation. Write self-contained briefs. Prefer `mode=handoff` + `handoff_compose` over pasting transcripts.

---

## `pane_write_many`

Batch write to multiple panes in **one** MCP call. Same per-item semantics as `pane_write`. Orchestrator profile only.

**Signature:**
```
pane_write_many(
  writes: Array<{
    paneId: string,
    text?: string,
    mode?: "handoff",
    task?: string,
    storyId?: string,
    acceptanceCriteria?: string[],
    fileList?: string[],
    handoffPath?: string,
    submit?: boolean
  }>   // 1–16 items
) → { ok: bool, results: [{ paneId, ok, mode?, charCount?, error? }] }
```

**When to use:** Pattern B parallel fan-out — after spawning N panes, prefer this over N separate `pane_write` calls.

**Partial failure:** one bad paneId does not abort the batch; check `results[]` per pane.

**Not a replacement for:** `squad_run_start` / template-driven runs with quality gates.

---

## `pane_wait_idle`

Block until the target pane returns to idle.

**Signature:**
```
pane_wait_idle(
  paneId: string,
  timeoutMs?: number   // default 120000 (2 min)
) → { ok: bool, idle: bool }
```

**When to call:** sync fan-in path — between `pane_write` and `pane_read`. Optional when using Pattern D (`handoff_list`).

---

## `pane_read`

Read the last N lines from a pane's terminal output buffer.

**Signature:**
```
pane_read(
  paneId: string,
  lastN?: number   // default 100. Max ~1000 (buffer cap)
) → { ok: bool, lines: string[] | string }
```

Use for PTY output. For structured worker deliverables, prefer `handoff_list` + `handoff_read`.

---

## `handoff_submit`

Worker pane submits a structured result to the vault inbox (`synko.handoff-inbox.v1`).

**Requires:** `X-Synko-Pane-Id` on the MCP connection (worker panes only).

**Signature:**
```
handoff_submit(
  summary: string,                    // short deliverable summary (required)
  status: "completed" | "blocked" | "failed",
  paneId?: string,                    // must match caller when provided
  storyId?: string,
  task?: string,
  acceptanceCriteria?: string[],
  fileList?: string[],
  decisions?: string[],
  nextSteps?: string[],
  mirrorMarkdown?: boolean,           // default true — writes .md mirror
  persist?: boolean                   // default false
) → { ok: true, entry: { entryId, vaultRelPath, ... }, hint }
```

**Vault path:** `projects/{projectId}/handoffs/inbox/{paneId}-{timestamp}.json`

**Worker brief:** tell workers to call this at task end when using Pattern D.

---

## `handoff_list`

Orchestrator lists inbox entries from the vault, newest first.

**Signature:**
```
handoff_list(
  storyId?: string,
  paneId?: string,
  status?: "completed" | "blocked" | "failed",
  sinceMinutes?: number   // default 60
) → { count: number, entries: [{ entryId, paneId, status, summary, submittedAt, vaultRelPath }] }
```

**When to use:** Pattern D async fan-in — poll after `pane_write_many` instead of blocking on every `pane_wait_idle`.

---

## `handoff_read`

Read a single inbox entry (full packet).

**Signature:**
```
handoff_read(
  entryId?: string,       // from handoff_list (paneId-timestamp)
  vaultRelPath?: string   // e.g. projects/.../handoffs/inbox/....json
) → { entry, packet }
```

---

## `pane_set_identity`

Register the agent's current skill/role identity on a pane.

**Signature:**
```
pane_set_identity(
  paneId: string,
  skill?: string,
  role?: string
) → { ok: bool }
```

**When to call:** after spawning a pane, to mark it with the appropriate role (e.g., "dev", "qa", "architect").

---

## `pane_kill`

Kill a pane process and clean up its tasks.

**Signature:**
```
pane_kill(paneId: string) → { ok: bool }
```

---

## `pane_open_browser`

Open a web browser pane inside the SynkOS workspace.

**Signature:**
```
pane_open_browser(url: string) → { paneId: string }
```

---

## `pane_open_terminal`

Spawn a new terminal pane inside the SynkOS workspace.

**Signature:**
```
pane_open_terminal(command?: string) → { paneId: string }
```

---

## `todo_manager`

Manages a structured, user-visible task list for milestone tracking.

**Signature:**
```
todo_manager(action, ...) where action is one of:

  set_tasks(tasks: string[], ...)
    — max 7 tasks. First becomes in_progress immediately.

  move_to_task(moveToTask: string, ...)
    — completes all prior tasks, sets the named task to in_progress.

  add_task(task: string)
    — appends a single task to the existing list.

  read_list()
    — view current state without changes.

  mark_all_done()
    — completes everything; signals project end.
```

**Use when:** projects have 3+ distinct, milestone-level deliverables.