# SynkOS Execution Harness (E22 + E29)

Native SynkOS layer inspired by **dotcontext** patterns (semantic map, policy gates, lifecycle hooks, sensors). Prefixo de contratos: `synkos.*`. Não depende de MCP externo dotcontext.

Disponível a partir de **v0.9.0**; kickoff cognitivo (E31) e delegação paralela (E32) a partir de **v1.0+**. Config em `.synko/config/`.

---

## 1. Context economy (E22)

### Tiers
| Tier | Quando | Leitura |
|------|--------|---------|
| `minimal` | typo, rename, fix pontual | story file apenas |
| `standard` | story ativa (default) | story + `wiki_query` ou `context_find` para fatos |
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

## 2. Handoff protocol (E29 + E32)

Substitui colar transcripts longos entre panes.

**Delegação single-pane:**
```
handoff_compose → handoff_persist (opcional) → pane_write(mode=handoff)
```

**Delegação paralela ad hoc (E32):**
```
pane_spawn × N → pane_write_many(mode=handoff) → workers → handoff_submit
orchestrator → handoff_list / handoff_read
```

- `handoff_compose` — monta pacote com task, storyId, roles, acceptanceCriteria, fileList (paths only), decisions, blockers, nextSteps
- `handoff_persist` — grava em vault (`projects/{id}/handoffs/` ou `sessions/`)
- `pane_write` / `pane_write_many` com handoff estruturado — worker lê contexto mínimo
- `handoff_submit` — worker persiste em `projects/{id}/handoffs/inbox/` (requer `X-Synko-Pane-Id`)
- `handoff_list` — orchestrator lista entradas recentes (polling; sem WebSocket)

**Regra:** `fileList` = paths, nunca conteúdo de arquivo.

**Não substitui** `squad_run_*` — templates com gates e memory policy continuam no fluxo de squad.

---

## 3. Cognitive kickoff (E31, v1.0+)

Kickoff greenfield/brownfield materializa projeto, vault e stories iniciais. Stories originadas do kickoff carregam `## Kickoff Metadata` com `kickoffOrigin: true` e `kickoffMode`.

### Artefatos por modo

| Modo | Outputs principais |
|------|-------------------|
| **brownfield** | `context_map_build` → mapa semântico; `projects/{id}/discovery/report.md`; `discovery/semantic-summary.md`; story `E0-D1` (draft até discovery run) |
| **greenfield** | `stackPreset` em `.synko/config/project.yaml` (`electron`, `node-api`, `python`, `generic`); seeds PRD/architecture/backlog; `projects/{id}/bootstrap/skill-profile.md` |

### Bootstrap workspace (ambos)

- Raiz do workspace: `AGENTS.md` + `CLAUDE.md` (Claude Code lê `CLAUDE.md`)
- `hook_install` (ou auto no bootstrap) — traces de sessões CLI standalone
- Defaults em `.synko/config/workspace.json` (tool budget, etc.)

### Policy `draft → ready` (kickoff only)

Além das regras de `done`, stories kickoff **não transitam para `ready` sem evidência**:

| Regra | Condição |
|-------|----------|
| `kickoff_brownfield_discovery_required_for_ready` | `projects/{projectId}/discovery/report.md` existe no vault |
| `kickoff_greenfield_bootstrap_required_for_ready` | `stackPreset` em `project.yaml` + `bootstrap/skill-profile.md` |

Sempre: `policy_check_story_transition(fromStatus: draft, toStatus: ready, storyId)` antes de `story_update`.

### Discovery Pack (brownfield)

1. `squad_seed_templates` — inclui template `brownfield-discovery` (orchestrator: `synko-sm`, worker: `synko-architect`)
2. `squad_run_start(templateId: "brownfield-discovery", activeStoryId: "E0-D1", ...)`
3. Após run + report válido → `policy_check_story_transition` → `story_update(status: ready)` para `E0-D1`

UI: stories kickoff em `draft` exibem badge **aguardando discovery** até evidence presente.

### Continuidade

- `session_resume` — retomar sessão anterior (perfil `minimal` sempre expõe)
- `wiki_query scope:sessions query:{story-id}` — último handoff antes de retomar trabalho
- `context_find query:{topic} sources:[wiki,memories] layer:auto` — busca unificada vault (E33); use em vez de N× `wiki_query` + `skill_list` ao explorar contexto

### Memória pós-sessão (E33-S4)

Após milestone (e **somente** se `session_handoff` condicional aplicar): seguir `references/session-memory-checklist.md`.

Atalho para decisões duráveis:

```text
wiki_ingest sourceType:session sourceId:{story} summary:"..." touchedPages:[sessions] promoteTrajectory:true
```

Isso append em `wiki/sessions` **e** `memories/trajectories.md` (timeline datada).

---

## 4. Execution gates & policy (E29)

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
| `policy_check_story_transition` | **obrigatório** antes de `story_update` → `ready` (kickoff) ou `done` |

Regras típicas:
- **kickoff `draft → ready`:** discovery report (brownfield) ou stackPreset + skill-profile (greenfield) — ver §3
- **`→ done`:** evidence completa para perfis code/infra
- **`→ done`:** `fileList` preenchido
- **`→ done`:** acceptance criteria `[x]` no markdown da story

---

## 5. Session traces (E29-S2/S5)

Timeline JSONL em vault. Auto-trace em `pane_spawn`, `handoff_*`, `gate_run_sensors`.

| Tool | Uso |
|------|-----|
| `trace_append` | evento manual |
| `trace_list` | sessões recentes |
| `trace_replay_summary` | replay compacto para UI/memória |

---

## 6. Lifecycle hooks — Claude + Codex (E29-S6/S7)

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

## 7. Fluxo canônico — story → done (code gate)

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

## 8. Fluxo canônico — delegar worker

**Single worker:**
```
pane_spawn(role: "synko-dev", ...)
handoff_compose(task, storyId, acceptanceCriteria, fileList, ...)
pane_write(paneId, mode=handoff, ...)
pane_wait_idle(paneId)
pane_read(paneId)
gate_run_sensors + policy_check_story_transition  // se worker fechou story
```

**Paralelo ad hoc (E32):**
```
pane_spawn × N
pane_write_many(writes: [{ paneId, mode: handoff, task, storyId }, ...])
// workers ao concluir:
handoff_submit(summary, status, storyId, fileList, ...)
// orchestrator quando pronto:
handoff_list(storyId, sinceMinutes)
```

---

## 9. O que NÃO fazer

- Assumir tool MCP existe sem `tool_budget_list`
- Colar `architecture.md` / `prd.md` em `pane_write` — usar `context_map_get` + handoff
- `story_update → ready` em story kickoff sem `policy_check_story_transition` (E31)
- `story_update → done` sem `policy_check_story_transition`
- `pane_spawn` sem `pane_write` / `pane_write_many` (pane fica idle)
- Workers delegados terminarem sem `handoff_submit` quando o brief pediu entrega estruturada (E32)
- Ignorar `hook_sync_events` em workflows Codex-only (memória fica cega)