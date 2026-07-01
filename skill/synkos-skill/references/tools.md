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
  cwd?: string           // absolute path; defaults to current workspace
) → { paneId: string, ... }
```

**Returns:** the new `paneId`. Save it — every subsequent `pane_write` / `pane_read` / `pane_wait_idle` needs it.

**Critical rule:** if `providerId` is anything other than `claude-oauth`, call `pane_list_providers()` first. Provider IDs are machine-local (e.g. `mimo-FxzXvc` on this machine, but might be `mimo-Abc123` elsewhere). Passing an unknown ID returns an error.

**Common pitfalls:**
- Passing a model the provider doesn't expose → error. Verify against `pane_list_providers()` output.
- Passing `cwd` outside the workspace → may work but file paths get confusing for the spawned pane.
- Spawning when `pane_list()` already shows an idle pane you could reuse → wasted setup time.

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
    providerType?: 'oauth' | 'anthropic-compat',
    providerLabel?: string,
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
  providers: [{
    id: string,
    label: string,
    type: 'oauth' | 'anthropic-compat',
    host: string,
    models: string[]
  }]
}
```

**Critical rule:** call this whenever you intend to use a non-default provider.

---

## `pane_write`

Type text into another pane's terminal as if the user typed it.

**Signature:**
```
pane_write(
  paneId: string,
  text: string,
  submit?: boolean   // default true
) → { ok: bool }
```

**Briefing principle:** the target pane has no memory of this conversation. Write self-contained briefs.

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

**When to call:** always between `pane_write` and `pane_read`.

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

**When to call:** after spawning a pane, to mark it with the appropriate role (e.g., "dev", "qa", "architect") and skill name.

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

---

## Execution harness tools (E22/E29, v0.9+)

Full flows and configs: **references/execution-harness.md**.

| Prefix | Tools |
|--------|-------|
| Context | `context_resolve_tier`, `context_map_build`, `context_map_get`, `context_map_semantic` |
| Tool budget | `tool_budget_status`, `tool_budget_list`, `tool_budget_set` |
| Handoff | `handoff_compose`, `handoff_persist` |
| Gates | `gate_sensors_list`, `gate_run_sensors`, `gate_evidence_status` |
| Policy | `policy_get`, `policy_evaluate`, `policy_check_story_transition` |
| Hooks | `hook_status`, `hook_install`, `hook_uninstall`, `hook_sync_events` |
| Traces | `trace_append`, `trace_list`, `trace_replay_summary` |

**Critical:** call `tool_budget_list` before assuming a harness tool is exposed. Call `policy_check_story_transition` before `story_update → done`.
