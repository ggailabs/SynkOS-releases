# SynkOS Recipes — Worked Examples

End-to-end orchestration recipes: the user request, why orchestration is the right move, and the exact tool sequence.

Modelos são referidos por **classe** (raciocínio-pesado / workhorse / bulk-barato — ver `providers.md`). Resolva IDs reais com `pane_list_providers()`.

---

## Recipe 1: Two-pane code review squad (critique → fix)

> User: "Review the auth flow I just merged and propose fixes."

Duas etapas cognitivas com dependência: **critique** (raciocínio pesado, achar problemas sem viés de implementação) e **remediation** (workhorse, escrever o patch a partir da crítica). O fixer depende do output do critic — sequencie pelo orchestrator, **nunca** por timing ("wait 5 minutes" é frágil e proibido).

```
# Turn 1 — critic
critic = pane_spawn(model: <raciocínio-pesado>, role: "synko-qa")
pane_write(critic, mode: "handoff", storyId: "...", task: """
Review src/auth/ (read every file). Output structured critique to /tmp/auth-review.md:
security issues (by severity), logic bugs, maintainability, what's done well.
Critique only — no fixes. Save and stop.""")
pane_wait_idle(critic, timeoutMs: 600000)

# Turn 2 — só depois que a crítica existe, dispare o fixer
fixer = pane_spawn(model: <workhorse>, role: "synko-dev")
pane_write(fixer, mode: "handoff", storyId: "...", task: """
Read /tmp/auth-review.md. For each issue, propose a concrete patch as unified diff
in /tmp/auth-fixes.diff. Don't apply changes.""")
pane_wait_idle(fixer, timeoutMs: 600000)

# Turn 3 — collect
Read("/tmp/auth-review.md"); Read("/tmp/auth-fixes.diff")
```

Separação de modelos dá crítica mais limpa; o orchestrator é quem sabe quando a dependência foi satisfeita.

---

## Recipe 2: Doc + implementation in parallel

> User: "Add a webhook endpoint for Stripe events. Include docs."

Docs e impl são independentes — ambos dependem da mesma spec, nenhum bloqueia o outro.

**Turn 1 — o orchestrator escreve a spec (âncora compartilhada), depois fan-out:**

```
Write("/tmp/stripe-webhook-spec.md", "<spec: endpoint, eventos, verificação de assinatura, SLA>")

impl = pane_spawn(model: <workhorse>, role: "synko-dev")
docs = pane_spawn(model: <bulk-barato>)     # docs são simples

pane_write_many(writes: [
  { paneId: impl, mode: "handoff", storyId: "...",
    task: "Read /tmp/stripe-webhook-spec.md. Implement endpoint following existing patterns in src/app/api/. Add tests, run typecheck. Save changed-files list to /tmp/impl-files.txt." },
  { paneId: docs, mode: "handoff", storyId: "...",
    task: "Read /tmp/stripe-webhook-spec.md. Write user docs at docs/integrations/stripe-webhooks.md: events, local testing, deploy checklist, troubleshooting." },
])
```

**Turn 2 — wait ambos; Turn 3 — verificar e reportar.**

**Pitfall:** não escreva a spec dentro de um sub-pane e faça o outro "esperar por ela" — input compartilhado sai do orchestrator antes do fan-out.

---

## Recipe 3: Multi-perspective brainstorm

> User: "I'm naming a new product. Help me brainstorm — give me a few angles."

Um modelo se auto-correlaciona; 3 providers divergem de verdade. A síntese (que só o orchestrator pode fazer) é onde está o valor.

```
providers = pane_list_providers()   # IDs por máquina — obrigatório

a = pane_spawn(model: <raciocínio-pesado>)
b = pane_spawn(providerId: <gemini>, model: <modelo do provider>)
c = pane_spawn(providerId: <codex>,  model: <modelo do provider>)

prompt = "<mesmo brief para os 3; cada um salva em /tmp/names-<provider>.md>"
pane_write(a, prompt); pane_write(b, prompt); pane_write(c, prompt)

# wait os 3 → ler os 3 arquivos → sintetizar os 5 mais fortes com justificativa
```

---

## Recipe 4: Long-running migration with todo_manager

> User: "Migrate payments from Stripe Checkout to Payment Intents — API, DB schema, webhooks, frontend."

Sequencial (cada etapa depende da anterior), 4–5 milestones, trabalho pesado num worker enquanto o orchestrator narra progresso.

```
todo_manager(action: "set_tasks", tasks: ["DB schema", "API routes", "Webhooks", "Frontend", "E2E tests"])

worker = <worker-id do system prompt, ou pane_list()>
# Por etapa:
pane_write(worker, mode: "handoff", task: "<etapa N autocontida: estado atual, alvo, outputs em /tmp/migration-N-*.md>")
pane_wait_idle(worker, timeoutMs: 600000-900000)
Read("/tmp/migration-N-summary.md")           # verificação do orchestrator
todo_manager(action: "move_to_task", ...)     # avança o visível — não batche
# ... repetir; ao final:
todo_manager(action: "mark_all_done")
```

O worker trabalha; o orchestrator fica livre para reportar, responder o usuário e decidir entre etapas.

---

## Recipe 5: Parallel fan-out with async fan-in (E32)

> User: "Audit these 4 modules in parallel and summarize findings when each finishes."

N workers independentes, orchestrator não bloqueia em N× `pane_wait_idle`. Workers entregam handoffs estruturados; orchestrator faz poll no inbox.

```
# Turn 1 — spawn + batch delegate
panes = ["auth","billing","webhooks","admin"].map(m =>
  pane_spawn(model: <workhorse>, role: "synko-qa"))

pane_write_many(writes: panes.map((paneId, i) => ({
  paneId, mode: "handoff", storyId: "E32-audit",
  task: `Audit src/${modules[i]}/: severity-ranked issues, file paths, suggested fixes. No code changes.
When finished: handoff_submit(summary, status, storyId: "E32-audit", fileList).`,
})))

# Turn 2 — orchestrator segue com outro trabalho, depois:
entries = handoff_list(storyId: "E32-audit", sinceMinutes: 60)
# quando count == workers esperados:
handoff_read(entryId: ...)   # packet completo, se necessário
```

Integração é manual — sem auto-merge. Para debug ao vivo de um pane específico, `pane_wait_idle` + `pane_read` ainda vale.

**vs Recipe 2:** lá, sync + artefatos no filesystem; aqui, vault inbox — melhor quando deliverables são estruturados e o orchestrator não deve bloquear.
**vs squad runs:** `squad_run_start` com template, gates e memory policy continua sendo o caminho para workflows repetíveis multi-fase.

---

## Choosing between recipes

| Situation | Recipe |
|-----------|--------|
| 2+ independent perspectives on same input | 3 (multi-model brainstorm) |
| Different cognitive jobs, output de um alimenta o outro | 1 (critique → fix, sequenciado) |
| Independent work products, shared spec | 2 (doc + impl in parallel) |
| N parallel workers, orchestrator stays unblocked | 5 (`pane_write_many` + `handoff_list`) |
| Sequential project, visible milestones, heavy work | 4 (worker + `todo_manager`) |
| One small task | None — just do it inline |

The shape of the work picks the recipe. If none fit, you probably don't need orchestration.
