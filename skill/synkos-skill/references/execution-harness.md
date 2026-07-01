# SynkOS Execution Harness (E22 + E29)

Native SynkOS layer inspired by **dotcontext** patterns (semantic map, policy gates, lifecycle hooks, sensors). Prefixo de contratos: `synkos.*`. Não depende de MCP externo dotcontext.

Disponível a partir de **v0.9.0**. Config em `.synko/config/`.

---

## 1. Context economy (E22)

### Tiers
| Tier | Quando | Leitura |
|------|--------|---------|
| `minimal` | typo, rename, fix pontual | story file apenas |
| `standard` | story ativa (default) | story + `wiki_query` para fatos |
| `full` | onboarding, discovery, épico | `context_map_semantic(compact)` antes de docs inteiros |

### Tools
- `context_resolve_tier` — resolve tier + perfil de tool budget a partir de story status, task route, role
- `context_map_build` — (re)gera mapa semântico do repo → `.synko/cache/semantic-map.json`
- `context_map_get` — fatia `navigation` / `keyFiles` / `stack` sem colar `architecture.md`
- `context_map_semantic` — texto compacto para bootstrap (modo `compact` ou `full`)

### Tool budget (E22-D)
Workspace pode **ocultar** tools MCP por perfil (`dev`, `qa`, `orchestrator`, `minimal`).

- Sempre permitidos: `tool_budget_status`, `tool_budget_list`
- Antes de assumir que uma tool existe: `tool_budget_list`
- Config: `.synko/config/workspace.json` → `mcpToolBudget`

### Slim bootstrap
Panes spawnados recebem prompt slim (`SYNKO_SYSTEM_PROMPT_SLIM`), não a enciclopédia completa. Skills carregam **on demand** via paths:
`.synko/skills/`, `.agents/skills/`, `.claude/skills/`

---

## 2. Handoff protocol (E29)

Substitui colar transcripts longos entre panes.

```
handoff_compose → handoff_persist (opcional) → pane_write(mode=handoff)
```

- `handoff_compose` — monta pacote com task, storyId, roles, acceptanceCriteria, fileList (paths only), decisions, blockers, nextSteps
- `handoff_persist` — grava em vault (`projects/{id}/handoffs/` ou `sessions/`)
- `pane_write` com handoff estruturado — worker lê contexto mínimo

**Regra:** `fileList` = paths, nunca conteúdo de arquivo.

---

## 3. Execution gates & policy (E29)

### Sensors & evidence
Stories com `gateProfile: code` ou `infra` exigem evidência antes de `done`.

| Tool | Uso |
|------|-----|
| `gate_sensors_list` | sensores built-in (test, typecheck, lint, …) |
| `gate_run_sensors` | executa sensores; grava evidence em vault |
| `gate_evidence_status` | lê estado da evidência da story |

Evidence path: `projects/{projectId}/evidence/{storyId}.json`

### Policy engine
Inspirado em dotcontext `policy.json`. Config: `.synko/config/execution-policy.json`

| Tool | Uso |
|------|-----|
| `policy_get` | regras ativas |
| `policy_evaluate` | simula transição |
| `policy_check_story_transition` | **obrigatório** antes de `story_update` → `done` |

Regras típicas:
- evidence completa para perfis code/infra
- `fileList` preenchido
- acceptance criteria `[x]` no markdown da story

---

## 4. Session traces (E29-S2/S5)

Timeline JSONL em vault. Auto-trace em `pane_spawn`, `handoff_*`, `gate_run_sensors`.

| Tool | Uso |
|------|-----|
| `trace_append` | evento manual |
| `trace_list` | sessões recentes |
| `trace_replay_summary` | replay compacto para UI/memória |

---

## 5. Lifecycle hooks — Claude + Codex (E29-S6/S7)

Bridge entre sessões **standalone** (CLI fora do pane SynkOS) e traces do vault.

| Tool | Uso |
|------|-----|
| `hook_status` | install status (`synkos.lifecycle-hooks.v1`) |
| `hook_install` | merge em `.claude/settings.json` + `.codex/hooks.json` + scripts `.synko/hooks/` |
| `hook_uninstall` | remove hooks SynkOS, preserva hooks estrangeiros |
| `hook_sync_events` | importa `.synko/cache/hooks/events.jsonl` → session traces |

**Fluxo Codex/Claude standalone:**
1. `hook_install` no workspace (ou auto no bootstrap)
2. Agente roda no terminal; hooks gravam eventos no cache
3. `hook_sync_events` após sessão — traces aparecem na aba Memória

Eventos: `session_start`, `post_tool_use` (matcher `mcp__synko__.*` no Claude), `session_end` / Codex `Stop`.

---

## 6. Fluxo canônico — story → done (code gate)

```
context_resolve_tier
  → ler docs/stories/{id}.md (tier standard)
  → implementar + testes
  → gate_run_sensors (storyId)
  → story_update (fileList)
  → policy_check_story_transition (toStatus: done)
  → story_update (status: done)  // só se policy passou
  → handoff_persist + story_checkpoint (se milestone)
```

Se `policy_check_story_transition` falhar: corrigir evidence/fileList/AC — não forçar `done`.

---

## 7. Fluxo canônico — delegar worker

```
pane_spawn(role: "synko-dev", ...)
handoff_compose(task, storyId, acceptanceCriteria, fileList, ...)
pane_write(paneId, mode=handoff, ...)
pane_wait_idle(paneId)
pane_read(paneId)
gate_run_sensors + policy_check_story_transition  // se worker fechou story
```

---

## 8. O que NÃO fazer

- Assumir tool MCP existe sem `tool_budget_list`
- Colar `architecture.md` / `prd.md` em `pane_write` — usar `context_map_get` + handoff
- `story_update → done` sem `policy_check_story_transition`
- `pane_spawn` sem `pane_write` (pane fica idle)
- Ignorar `hook_sync_events` em workflows Codex-only (memória fica cega)