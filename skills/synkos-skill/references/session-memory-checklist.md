# Post-session memory checklist (E33-S4)

Use **após milestone de story** ou quando os critérios de `session_handoff` forem atingidos — não a cada mensagem.

## Quando gerar `session_handoff`

Mantém regra AGENTS.md (inalterada):

- Sessão > 5 minutos, **ou**
- > 3 arquivos modificados, **ou**
- Decisão arquitetural ou de produto

Caso contrário: `story_checkpoint` apenas.

## Checklist de promoção

| # | Se… | Destino | Como |
|---|-----|---------|------|
| 1 | Handoff condicional disparou | `wiki/sessions` | `wiki_ingest` `touchedPages:[sessions]` |
| 2 | Decisão durável (produto/arquitetura) | `memories/trajectories` | `wiki_ingest` + **`promoteTrajectory: true`** |
| 3 | Entidade / glossário novo | `memories/entities` | `vault_append` ou `wiki_ingest` → `entities` |
| 4 | Preferência operacional nova | `memories/preferences` | `vault_append` |
| 5 | Padrão de código validado | `wiki/patterns` | `wiki_ingest` `touchedPages:[patterns]` |

## Exemplo — sessão com decisão

```text
1. session_handoff → .synko/vault/projects/{id}/sessions/session-{date}-{story}.md
2. wiki_ingest:
     sourceType: session
     sourceId: E33-S4
     summary: "Adopted native context layers"
     touchedPages: [sessions]
     promoteTrajectory: true
     content: |
       ## Decisões
       - Cherry-pick OpenViking sem runtime externo
       ## Próximos passos
       - Monitorar token savings em tier Standard
3. wiki_query scope:memories query:trajectories layer:auto
```

## O que **não** promover

- Debug transitório, typos, tentativas falhas
- Conteúdo já coberto por story `done` sem valor além do backlog
- Duplicatas de `AGENTS.md` / `architecture.md` — referencie por path

## Verificação rápida

```text
context_find query:{story-id} sources:[wiki,memories] layer:auto
```

Trajetória datada deve aparecer em `memories/trajectories.md` com sidecar L1 atualizado.