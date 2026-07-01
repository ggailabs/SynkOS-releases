# GG.AI Labs SynkOS AGENTS.md

## Regra de ouro

Nenhum agente trabalha sem contexto, nenhuma task termina sem memória, e nenhuma memória fica presa a um único agente.

---

## Carregamento de contexto (tiers)

Nem toda task exige leitura completa. Escolha o tier adequado:

### Minimal (tasks triviais: fix typo, rename, resposta rápida)
1. `wiki_query` para o tópico específico

### Standard (trabalho em story ativa — padrão)
1. Ler a story ativa em `docs/stories/{id}.md`
2. `wiki_query` para padrões e decisões relevantes

### Full (onboarding, novo projeto, primeira sessão)
1. `context_map_semantic(compact)` quando disponível
2. Ler `docs/architecture.md`, `docs/prd.md`, `docs/backlog.md`, `docs/stories/index.md`
3. Ler a story ativa em `docs/stories/{id}.md`

**Regra**: default é **Standard**. Escalar para Full apenas quando o contexto está genuinamente ausente. Preferir `wiki_query` e `context_map_get` a ler documentos inteiros.

Use `context_resolve_tier` quando story status ou categoria da task for ambíguos.

---

## Execution harness (E22/E29, v0.9+)

Camada MCP nativa (inspirada em dotcontext). Referência: `skills/synkos-skill/references/execution-harness.md`.

| Fase | Tools |
|------|-------|
| Contexto | `context_resolve_tier`, `context_map_*`, `tool_budget_list` |
| Delegação | `handoff_compose`, `handoff_persist`, `pane_write(handoff)` |
| Gates | `gate_run_sensors`, `gate_evidence_status` |
| Policy | `policy_check_story_transition` antes de `story_update → done` |
| CLI standalone | `hook_install`, `hook_sync_events` (Claude + Codex) |
| Observabilidade | `trace_list`, `trace_replay_summary` |

---

## Ao concluir qualquer task

1. Atualizar `fileList` da story via `story_update`
2. Marcar acceptance criteria cumpridos
3. Respeitar o `gate_profile` da story ao validar:
   - `code` → `gate_run_sensors` + lint/typecheck/test
   - `infra` → smoke test, rollback note
   - `docs` → revisão de conteúdo
   - `discovery` → findings documentados
4. `policy_check_story_transition` antes de marcar `done`
5. Criar ADR se houver decisão arquitetural

### Session handoff (condicional)

Gerar `session_handoff` em `.synko/vault/projects/{projectId}/sessions/session-{YYYY-MM-DD}-{story-id}.md` **apenas quando**:
- Sessão durou > 5 minutos, OU
- Mais de 3 arquivos foram modificados, OU
- Uma decisão arquitetural ou de produto foi tomada

Para progresso intermediário que não atinge esses critérios, usar `story_checkpoint`.

---

## Princípio operacional

`MCP/Runtime First → Observability Second → UI Third`

---

## Referências

- `skills/synkos-skill/` — orquestração + execution harness
- Skills de role: `skills/synko-{dev,qa,sm,architect,...}/`