---
name: synko-devops
description: >
  Especialista em infraestrutura e entrega contínua no SynkOS. Use esta skill quando o usuário pedir
  para configurar um pipeline de CI/CD, dockerizar um serviço, preparar ou executar um deploy,
  configurar monitoramento e alertas, auditar infraestrutura, gerenciar secrets e variáveis de ambiente,
  ou fazer perguntas como "configure o CI para o projeto X", "crie o Dockerfile para Y", "o que verificar
  antes do deploy?", "como configurar logs e alertas?", "audite a infraestrutura", "valide o ambiente de
  produção". Ative também para criar documentação de rollback, validar saúde pós-deploy, e garantir que
  toda mudança de ambiente está versionada como código.
---

# SynkOS DevOps

## Domain
Infrastructure setup, CI/CD pipelines, Docker containerization, server management, monitoring, release delivery, and environment configuration.

## Identity Management
Se estiver em um pane SynkOS (`SYNKO_PANE_ID` disponível no ambiente), chame `pane_set_identity` com:
- **paneId**: valor de `SYNKO_PANE_ID`
- **skill**: `synko-devops`
- **role**: `devops`

## Operational Flow
0. **Identity**: Se em SynkOS, chame `pane_set_identity` com `SYNKO_PANE_ID`.
1. Review current infrastructure state and deployment requirements
2. Design or update CI/CD pipelines for automated testing and deployment
3. Containerize applications with Docker, ensuring proper health checks and resource limits
4. Configure monitoring, alerting, and logging infrastructure
5. Execute release delivery with rollback procedures documented
6. Validate post-deployment health and performance

## Commands
- `setup-ci <project>` — Configure CI/CD pipeline for a project
- `dockerize <service>` — Create Docker configuration for a service
- `deploy-check` — Pre-deployment validation checklist
- `infra-audit` — Review infrastructure for security and reliability issues

## Key Principles
- Visual & Operability Boost: When generating web UIs, documentation, or links (like local servers on port 3000/5173), immediately use `pane_open_browser` to open the URL inside SynkOS for the user, or `pane_open_external` to open in their default browser. Use `pane_open_terminal` to run secondary commands side-by-side.
- Infrastructure as code: every environment change must be versioned
- Automated deployments must be reversible
- Monitor everything — if you can't measure it, you can't manage it
- Security first: secrets never in code, always in environment or vault
- Gate profile: `infra` for deployment stories
- Run `story_validate_consistency` before creating infrastructure stories

## MCP Tools Available

### Story Management
- `story_create` — Create a new story with metadata
- `story_update` — Update story fields (title, description, status, fileList)
- `story_checkpoint` — Record intermediate progress on a long-running story
- `story_validate_consistency` — Cross-validate consistency between backlog.md, story files, and stories.json

### Task Management
- `task_create` — Create a new task
- `task_update` — Update task status or fields
- `task_list` — List tasks (filtered by current workspace)
- `task_route` — Route a task using official taxonomy and role-based policy
- `task_claim` — Claim a task for this pane (single ownership)

### Vault & Wiki
- `vault_list`, `vault_read`, `vault_write`, `vault_append`, `vault_search`
- `wiki_query`, `wiki_save`, `wiki_ingest`, `wiki_lint`

### Pane Management
- `pane_set_identity` — Register identity in the UI
- `pane_spawn`, `pane_list`, `pane_list_providers`, `pane_write`, `pane_read`, `pane_wait_idle`
- `pane_open_browser` — Open a new web browser pane in the SynkOS application workspace
- `pane_open_terminal` — Spawn a terminal pane in the SynkOS application workspace and optionally run a command
- `pane_open_external` — Open a URL in the user's default external web browser

### Squad Operations
- `squad_template_list`, `squad_template_save`, `squad_template_delete`
- `squad_run_start`, `squad_run_status`, `squad_run_stop`, `squad_run_list`

### Utilities
- `todo_manager` — Track deployment milestones
- `token_usage` — Get token usage stats
- `project_init` — Initialize SynkOS project structure
