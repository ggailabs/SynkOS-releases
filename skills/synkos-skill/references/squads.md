# SynkOS Squad Templates

Squad templates define reusable orchestrator + worker configurations for multi-pane orchestration. Templates are managed via SynkOS MCP tools and stored in the project vault.

---

## Creating a squad template

Use `squad_template_save` to define a template with orchestrator and worker pane configurations:

```
squad_template_save(
  id: "code-review",
  name: "Code Review Squad",
  orchestrator: { providerId: "claude-oauth", model: "claude-opus-4-7" },
  workers: [
    { providerId: "claude-oauth", model: "claude-sonnet-4-6", role: "reviewer" }
  ],
  qualityGate: { enabled: true, role: "qa", requiredPhases: ["review"], autoStart: true },
  memoryPolicy: { scope: "project", handoffRequired: true, wikiUpdateRequired: true }
)
```

---

## Starting a squad run

Use `squad_run_start` with a saved template and assign to a story:

```
squad_run_start(
  templateId: "code-review",
  projectId: "synkos",
  goal: "Review auth flow implementation",
  activeStoryId: "E1-S4",
  activeTaskIds: ["task-123"]
)
```

---

## Managing templates

| Action | Tool |
|--------|------|
| List templates | `squad_template_list` |
| Create/update template | `squad_template_save` |
| Delete template | `squad_template_delete` |
| Seed default templates | `squad_seed_templates` |

---

## Managing runs

| Action | Tool |
|--------|------|
| Start a run | `squad_run_start` |
| Check run status | `squad_run_status` |
| Stop a run | `squad_run_stop` |
| List runs | `squad_run_list` |

---

## Squad vs solo pane: which to use?

| Situation | Use |
|-----------|-----|
| Multi-step workflow with handoffs | Create a squad template and start a run |
| Independent execution that would block this pane | Spawn a single worker pane via `pane_spawn` |
| Parallel subtasks, same model | Fan-out: spawn N panes, write to all in one turn |
| Different cognitive jobs, different models | Multi-model squad (Pattern C in SKILL.md) |

Squad templates add structure (quality gates, memory policy). A plain `pane_spawn` is lighter but has no lifecycle tracking. Choose based on whether you need formal handoffs and verification steps.
