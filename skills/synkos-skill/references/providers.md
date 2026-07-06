# Providers & Model Selection

Which provider/model to reach for in which situation.

**Regra nº 1:** IDs de provider e listas de modelos são **por máquina** e mudam entre releases. Nunca hardcode — resolva em runtime:

```
providers = pane_list_providers()
# → [{ id, label, type, host, models }]
```

O provider default (Claude) dispensa `providerId` em `pane_spawn`. Qualquer outro: use o `id` e um `model` retornados por `pane_list_providers()` nesta máquina.

---

## Heurística de escolha (por classe de trabalho, não por nome de modelo)

| Classe | Perfil de modelo | Quando |
|--------|------------------|--------|
| **Raciocínio pesado** | Tier mais capaz do provider Claude (Opus/superior) | Decisões arquiteturais, security review, specs ambíguas — quando errar o julgamento custa caro |
| **Workhorse** | Tier intermediário Claude (Sonnet) | Implementação geral, refactors multi-arquivo, testes, a maior parte da orquestração. **Default quando em dúvida** |
| **Bulk barato** | Tier rápido Claude (Haiku) ou provider anthropic-compat de custo baixo | Sweeps paralelos bem especificados, docs, transformações mecânicas, análise de logs |
| **Busca web / fatos frescos** | Provider Gemini | Tarefas "look up current X" ou segunda opinião estilística |
| **Voz divergente** | Provider Codex/GPT | Algoritmos clássicos ou terceira perspectiva em brainstorms A/B/C |

---

## Decision matrix

| Task | Classe recomendada |
|------|--------------------|
| Architecture / hard design call | Raciocínio pesado |
| New feature implementation | Workhorse |
| Single-file edit, refactor | Workhorse (ou inline no pane atual) |
| Test generation | Workhorse |
| Doc writing | Bulk barato |
| 10+ parallel mechanical edits | Bulk barato |
| Web search / fresh facts | Gemini |
| Multi-perspective brainstorm | 1 pane de cada provider disponível |
| Security review | Raciocínio pesado |
| Fix-it after critique | Workhorse |
| Long-running migration step | Workhorse em worker pane |

---

## Pitfalls

1. **Hardcoding provider IDs** — o mesmo provider tem sufixo diferente em cada instalação. Sempre `pane_list_providers()` antes de provider não-default.
2. **Tier máximo para tudo "por segurança"** — lento e caro. Workhorse resolve a maioria; escale só quando profundidade de raciocínio importa.
3. **Bulk barato para tarefas ambíguas** — perde nuance. Reserve para trabalho mecânico bem especificado.
4. **Tratar provider anthropic-compat como drop-in do Claude** — comportamento próximo mas não idêntico; verifique outputs em trabalho crítico.
5. **Misturar modelos aleatoriamente** — diversidade ajuda em brainstorm; para execução, um modelo por tarefa coerente.
