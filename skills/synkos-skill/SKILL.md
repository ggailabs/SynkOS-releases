---
name: synkos-skill
version: 1.1.0
description: Master skill for SynkOS multi-agent orchestration. Use whenever you need to spawn panes, delegate work to agents, manage parallel execution, coordinate multi-model squads, or use todo_manager.
---

# SynkOS Skill

You are running inside SynkOS — a multi-agent orchestration platform. Each Claude session is a visible pane in a workspace grid. You can spawn more panes, delegate work to them, run multiple models in parallel, and orchestrate squad runs.

This file covers the decision tree and must-know patterns. For depth, read the relevant reference file **only when needed**:

- **references/tools.md** — assinaturas completas, return shapes e edge cases da API pane/handoff/todo
- **references/execution-harness.md** — context tiers, tool budget, handoff protocol, gates, policy, hooks (Claude+Codex), traces
- **references/session-memory-checklist.md** — o que promover após sessão (`trajectories`, `entities`, `wiki_ingest promoteTrajectory`)
- **references/recipes.md** — worked end-to-end examples (review squad, doc+impl paralelo, brainstorm multi-modelo, migração longa, fan-in assíncrono)
- **references/providers.md** — classe de modelo por tipo de trabalho; IDs sempre via `pane_list_providers()`
- **references/squads.md** — squad templates e quando preferir run com gates a fan-out ad hoc

SKILL.md alone is enough for most pane decisions; read **execution-harness.md** before closing stories or syncing Codex/Claude standalone sessions.

---

## Skill activation (mandatory — token economy)

When the user invokes `synkos-skill` **without a concrete task** (e.g. "ativa a skill", "synkos-skill", projeto novo sem objetivo):

- Reply in **≤10 lines**. No tables, no tool matrices, no Pattern A–D dump.
- **Do NOT** call `tool_budget_list`, `pane_list`, `context_map_*`, or read `references/*.md` unless the user explicitly asks.
- **Do NOT** list blocked/allowed MCP tools or orchestration cookbooks unprompted.
- Say: skill active → project/workspace if known → backlog/story in one line → **one question** about intent.

Example (enough):

> SynkOS skill ativo. Projeto: X. Sem story ativa; backlog: Y. O que você quer fazer?

When the user **has a concrete task**: skip activation ceremony — execute inline or delegate per the decision tree below. Invoking the skill is not permission to audit the harness.

---

## Execution harness — resumo

SynkOS não é só spawn de panes. O fluxo completo MCP:

1. **Context economy** — `context_resolve_tier`; mapa via `context_map_semantic`/`context_map_get`; `tool_budget_list` antes de assumir que uma tool rara existe
2. **Kickoff (E31)** — policy `draft → ready` exige discovery report (brownfield) ou `stackPreset` + skill-profile (greenfield) — `execution-harness.md` §3
3. **Delegação** — `handoff_compose` → `pane_write(handoff)` ou `pane_write_many` (fan-out); workers `handoff_submit`; orchestrator `handoff_list` (fan-in assíncrono)
4. **Gates** — `gate_run_sensors` + `policy_check_story_transition` antes de `story_update → done` (e `→ ready` em stories kickoff)
5. **Observabilidade** — traces auto + `hook_sync_events` para sessões CLI standalone

---

## Stories: fonte de verdade e índice derivado

Para criar ou reorganizar stories, siga este fluxo e não o substitua por edição de Markdown:

1. `story_validate_consistency` para verificar o estado atual.
2. Escolha IDs ainda inexistentes e informe `epicId` em cada `story_create` (ou use `story_update` para uma story existente).
3. Ao concluir um lote, execute `story_rebuild_index` para regenerar `docs/stories/index.md`, `docs/backlog.md` e o store a partir das stories canônicas.

`docs/stories/index.md` e `docs/backlog.md` são **derivados**; nunca os edite manualmente. Também não edite `docs/stories/*.md` como atalho. Se uma tool necessária estiver fora do budget, reporte o bloqueio ao usuário/orquestrador — não use operações de arquivo como fallback.

---

## The first decision: do anything special at all?

Most user requests don't need orchestration. Default to handling things inline. Reach for SynkOS tools only on one of these signals:

```
Is the work parallelizable?           → spawn panes
Does it need a different model?        → spawn pane with that model
Does it have 3+ distinct milestones?   → todo_manager
Will it block this pane for >5 min?    → spawn pane, return to user immediately
Does the user say "in parallel"?       → spawn panes, no further deliberation
None of the above?                     → just do the task. Don't perform orchestration.
```

Spawning a pane has cost: setup time (~5-10s), separate context (zero memory of this conversation), and you have to brief it well. If a task takes 2 min inline, delegating is slower.

Também **não** invoque orquestração para: perguntas de conhecimento puro, bug fix/refactor single-file, ou menção casual a "pane"/"agent" no meio de outro assunto.

Assinaturas e edge cases de todas as tools: `references/tools.md`. Perfis: `pane_write_many` e `handoff_list` são orchestrator-only; workers usam `handoff_submit`. `squad_run_*` (templates com gates) continua sendo o caminho para trabalho multi-fase estruturado — Patterns B/D são para delegação **ad hoc**.

---

## The four must-know patterns

### Pattern A: delegate to the worker pane (most common)

You always have a worker pane available — its ID is at the top of your system prompt under "squad orchestrator worker" (or discover via `pane_list()` and reuse an idle pane before spawning).

```
pane_write(paneId: <worker-id>, mode: "handoff", task: "<self-contained task>", storyId: "...")
pane_wait_idle(paneId: <worker-id>, timeoutMs: 300000)   # antes de pane_read — ler pane rodando retorna output parcial
pane_read(paneId: <worker-id>, lastN: 200)
```

The worker has no memory of this conversation. Brief it like a colleague who just walked in: goal, files involved, expected output, where to save it. Prefer `mode=handoff` + `handoff_compose` over raw text dumps — vague briefs are the #1 delegation failure.

### Pattern B: parallel fan-out (prefer `pane_write_many`)

Work splits into N independent subtasks. Spawn N panes, then write to **all in one tool call**:

```
# Turn 1 — spawn all, then batch write (one MCP call, max 16 items)
a = pane_spawn(model: <workhorse>, role: "synko-dev")
b = pane_spawn(model: <workhorse>, role: "synko-dev")
pane_write_many(writes: [
  { paneId: a, mode: "handoff", task: "<task A>", storyId: "..." },
  { paneId: b, mode: "handoff", task: "<task B>", storyId: "..." },
])
```

One atomic batch com partial-failure report por pane. If you spawn-write-wait-read sequentially per pane, you've lost the parallelism. Sempre passe `role` no spawn (ou `pane_set_identity` depois) para o tool routing funcionar.

### Pattern C: multi-model squad

Different models for different cognitive jobs. **Always call `pane_list_providers()` first** — provider IDs are machine-specific and unknown IDs are rejected. Escolha por classe (ver `providers.md`): raciocínio-pesado para arquitetura/review crítico, workhorse para execução, bulk-barato para sweeps, Gemini para busca web, Codex para voz divergente.

### Pattern D: async fan-in (`handoff_submit` + `handoff_list`)

After Pattern B fan-out, workers return structured results **without** the orchestrator blocking on every pane. Inclua no brief do worker: ao terminar, `handoff_submit(summary, status, storyId, fileList)` — sem isso o fan-in fica cego.

```
# Orchestrator, quando pronto (após outro trabalho ou timer):
handoff_list(storyId: "...", sinceMinutes: 30)
handoff_read(entryId: "<paneId-timestamp>")   # opcional — packet completo
```

Vault: `.synko/vault/projects/{projectId}/handoffs/inbox/{paneId}-{ts}.json`. Sync collection (`pane_wait_idle` + `pane_read`) still works for live PTY output. Integração é manual — no auto-merge.

---

## todo_manager: when, how, and why

Use when the project has **3+ distinct, milestone-level tasks**. Skip for single-task work — it's overhead.

```
todo_manager(action: "set_tasks", tasks: [...])    # max 7 — first becomes in_progress
todo_manager(action: "move_to_task", moveToTask: "...")  # imediatamente ao concluir cada milestone — não batche
todo_manager(action: "mark_all_done")              # at the end
```

Milestone-level only: "Wire up signup form" reads as progress; "Add import statement" reads as filler. Live progress is the feature — `todo_manager` é UI, não substituto de ownership de tasks (`task_create`/`task_claim`).

---

## Worker-pane caveat

You may be the orchestrator, but you may also be a worker pane that another orchestrator is delegating to. If your initial prompt looks like a self-contained task with no system framing about being an orchestrator, you're a worker — execute the task directly, then call `handoff_submit` when done if the brief asked for it. Don't try to spawn more panes for it.
