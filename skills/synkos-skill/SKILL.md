---
name: synkos-skill
version: 1.0.2
description: Master skill for SynkOS multi-agent orchestration. Use whenever you need to spawn panes, delegate work to agents, manage parallel execution, coordinate multi-model squads, or use todo_manager.
---

# SynkOS Skill

You are running inside SynkOS — a multi-agent orchestration platform. Each Claude session is a visible pane in a workspace grid. You can spawn more panes, delegate work to them, run multiple models in parallel, and orchestrate squad runs.

This file covers the decision tree and must-know patterns. For depth, read the relevant reference file:

- **references/tools.md** — pane/task/story MCP API (orchestration surface)
- **references/execution-harness.md** — **E22/E29**: context tiers, tool budget, handoff protocol, gates, policy, hooks (Claude+Codex), traces (dotcontext-inspired)
- **references/recipes.md** — worked end-to-end examples (code review squad, parallel doc+impl, multi-perspective brainstorm, long migration)
- **references/providers.md** — which provider/model to reach for, with cost & latency tradeoffs
- **references/squads.md** — SynkOS squad templates and multi-pane orchestration patterns

Read these only when needed. SKILL.md alone is enough for most pane decisions; read **execution-harness.md** before closing stories or syncing Codex/Claude standalone sessions.

---

## Execution harness (v0.9+) — resumo

SynkOS não é só spawn de panes. O fluxo completo MCP:

1. **Context economy** — `context_resolve_tier`; mapa via `context_map_semantic` / `context_map_get`; `tool_budget_list` antes de tools raras
2. **Delegação** — `handoff_compose` → `pane_write(handoff)` ou `pane_write_many` (fan-out); workers `handoff_submit`; orchestrator `handoff_list` (fan-in assíncrono)
3. **Gates** — `gate_run_sensors` + `policy_check_story_transition` antes de `story_update → done`
4. **Observabilidade** — traces auto + `hook_sync_events` para sessões CLI (`.codex/hooks.json`, `.claude/settings.json`)

Detalhes, configs e anti-patterns: `references/execution-harness.md`.

---

## The first decision: do anything special at all?

Most user requests don't need orchestration. Default to handling things inline. Reach for SynkOS tools only when the task genuinely benefits from one of these signals:

```
Is the work parallelizable?           → spawn panes
Does it need a different model?        → spawn pane with that model
Does it have 3+ distinct milestones?   → todo_manager
Will it block this pane for >5 min?    → spawn pane, return to user immediately
Does the user say "in parallel"?       → spawn panes, no further deliberation
None of the above?                     → just do the task. Don't perform orchestration.
```

Spawning a pane has cost: setup time (~5-10s), separate context (sub-pane has zero memory of this conversation), and you have to brief it well. If a task takes you 2 min inline, delegating is slower, not faster.

---

## The tools at a glance

| Tool | Purpose | When to call |
|------|---------|--------------|
| `pane_list` | Discover existing panes | Before spawning — reuse idle panes when possible |
| `pane_list_providers` | List configured LLMs | Before spawning with a non-default provider |
| `pane_spawn` | Open new pane | Got a parallelizable subtask |
| `pane_write` | Send prompt to one pane | Single delegation |
| `pane_write_many` | Batch write to N panes | **Preferred** for parallel fan-out (orchestrator profile) |
| `pane_wait_idle` | Block until pane done | Sync fan-in — before `pane_read` |
| `pane_read` | Get pane PTY output | After `pane_wait_idle` (sync collection) |
| `handoff_submit` | Worker posts structured result | End of worker task (requires `X-Synko-Pane-Id`) |
| `handoff_list` | Orchestrator polls inbox | Async fan-in after parallel delegation |
| `handoff_read` | Read one inbox entry | When you need full packet from `handoff_list` |
| `pane_set_identity` | Register skill/role on a pane | When spawning a pane for a specific role |
| `pane_kill` | Kill a pane process | Cleanup when a pane is stuck or no longer needed |
| `pane_open_browser` | Open a browser pane | When the task needs web interaction |
| `pane_open_terminal` | Spawn terminal pane | For shell commands or long-running processes |
| `todo_manager` | Visible task list | Projects with 3+ milestones |

Full signatures, return shapes, and edge cases live in `references/tools.md`.

**Tool budget:** `pane_write_many` and `handoff_list` are orchestrator-only. Workers use `handoff_submit`. Call `tool_budget_list` if unsure.

**Squad runs:** `squad_run_*` templates with gates remain the path for structured multi-phase work. Patterns B/D are for **ad hoc** parallel delegation — they complement, not replace, squad runs.

---

## The four must-know patterns

### Pattern A: delegate to the worker pane (most common)

You always have a worker pane available — its ID is at the top of your system prompt under "squad orchestrator worker". Default `T06AfShP`. Use it for execution work that would block this pane.

```
pane_write(paneId: <worker-id>, mode: "handoff", task: "<self-contained task>", storyId: "...")
pane_wait_idle(paneId: <worker-id>, timeoutMs: 300000)   # 5 min for non-trivial
pane_read(paneId: <worker-id>, lastN: 200)
```

The worker has no memory of this conversation. Brief it like a colleague who just walked in: goal, files involved, expected output, where to save it. Prefer `mode=handoff` + `handoff_compose` over raw text dumps.

### Pattern B: parallel fan-out (prefer `pane_write_many`)

Work splits into N independent subtasks. Spawn N panes, then write to **all in one tool call** with `pane_write_many`.

```
# Turn 1 — spawn all panes
a = pane_spawn(model: "claude-sonnet-4-6", role: "synko-dev")
b = pane_spawn(model: "claude-sonnet-4-6", role: "synko-dev")

# Turn 1 (same turn) — batch write (one MCP call)
pane_write_many(writes: [
  { paneId: a, mode: "handoff", task: "<task A>", storyId: "..." },
  { paneId: b, mode: "handoff", task: "<task B>", storyId: "..." },
])
```

**Why `pane_write_many` over N× `pane_write`:** one atomic batch, partial-failure reporting per pane, and models don't have to guess they should batch multiple tool calls. Max 16 items per batch.

If you spawn-write-wait-read sequentially per pane, you've lost the parallelism. The whole point is concurrent execution.

### Pattern C: multi-model squad

Different models for different cognitive jobs in the same task. **Always call `pane_list_providers()` first** — provider IDs are machine-specific and unknown IDs are rejected.

```
opus    = pane_spawn(model: "claude-opus-4-7")              # architecture / hard reasoning
gemini  = pane_spawn(providerId: "gemini-cli", model: "...") # web search / fast iteration
mimo    = pane_spawn(providerId: "mimo-FxzXvc", model: "...") # cheap bulk work
```

See `references/providers.md` for which model to reach for in which situation.

### Pattern D: async fan-in (`handoff_submit` + `handoff_list`)

After Pattern B fan-out, workers can return structured results **without** the orchestrator blocking on `pane_wait_idle` + `pane_read` for every pane.

**Worker pane** (end of task):

```
handoff_submit(
  summary: "Implemented webhook handler; 3 files changed",
  status: "completed",
  storyId: "...",
  task: "...",
  fileList: ["src/..."],
)
```

**Orchestrator** (poll when ready — e.g. after other work or on a timer):

```
handoff_list(storyId: "...", sinceMinutes: 30)
handoff_read(entryId: "<paneId-timestamp>")   # optional — full packet
```

Vault path: `.synko/vault/projects/{projectId}/handoffs/inbox/{paneId}-{ts}.json`

Sync collection (`pane_wait_idle` + `pane_read`) still works when you need live PTY output. Pattern D is for structured deliverables the orchestrator integrates manually — no auto-merge.

---

## todo_manager: when, how, and why

Use when the project has **3+ distinct, milestone-level tasks** ("Build auth", "Add database", "Create dashboard"). Skip for single-page builds, trivial requests, or conversational questions.

```
todo_manager(action: "set_tasks", tasks: [...])    # max 7 — first becomes in_progress
todo_manager(action: "move_to_task", moveToTask: "Add database")  # call as soon as a task completes
todo_manager(action: "mark_all_done")              # at the end
```

Why milestone-level only: micro-steps create noise, the user scans for progress at a glance. "Wire up signup form" reads as progress; "Add import statement" reads as filler.

Call `move_to_task` immediately when each milestone completes — don't batch. Live progress is the feature.

---

## When NOT to invoke this skill

- "What is X?" / "explain Y" — pure knowledge questions, no orchestration involved
- Bug fixes, refactors, single-file edits — inline work, no parallelism
- Anything where the user is mid-conversation about an unrelated topic and just mentions "open" or "pane" or "agent" in passing

The skill triggers when there's actual orchestration work. If in doubt, just do the task.

---

## Common mistakes

1. **Reading before waiting** — `pane_read` on a running pane returns partial output. Always `pane_wait_idle` first (sync path).
2. **N× `pane_write` when `pane_write_many` fits** — use the batch tool for parallel delegation.
3. **Sequential when parallel was possible** — spawn + `pane_write_many` belong in minimal turns, not one pane per turn.
4. **Vague briefs to sub-panes** — they have zero context. Spell out files, goals, output format, save path.
5. **Spawning when worker exists** — call `pane_list()` first, reuse the idle worker.
6. **Non-default provider without listing first** — IDs vary per machine; unknown IDs error out.
7. **Micro-step todos** — todo_manager is for 3-7 milestones, not every action.
8. **Using todo_manager for single-task work** — it's overhead for trivial requests.
9. **Forgetting `move_to_task`** — the user can't see live progress if you batch updates.
10. **Forgetting `pane_set_identity`** — always register the role/skill on spawned worker panes so tools can route properly.
11. **Workers forgetting `handoff_submit`** — orchestrator can't use `handoff_list` if workers only write to PTY.
12. **Replacing `squad_run_*` with ad hoc fan-out** — use templates when gates, phases, and memory policy matter.

---

## Worker-pane caveat

You may be the orchestrator, but you may also be a worker pane that another orchestrator is delegating to. If your initial prompt looks like a self-contained task with no system framing about being an orchestrator, you're a worker — execute the task directly, then call `handoff_submit` when done if the brief asked for it. Don't try to spawn more panes for it.