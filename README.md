# SynkOS Releases

> Multi-agent terminal orchestrator for AI-powered development workflows

## Latest Version: v0.9.0

**SynkOS** is the operational layer for multi-agent AI development. It integrates MCP as internal contract, squads as traceable execution units, stories as planning primitives, vault/wiki as persistent memory, and a UI for observability and operational control.

---

## Downloads

### Linux

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.9.0.AppImage` | ~150 MB | Universal Linux executable (recommended) |
| `synko_0.9.0_amd64.deb` | ~124 MB | Debian/Ubuntu installation package |

**Installation (AppImage):**
```bash
# Download and make executable
chmod +x SynkOS-0.9.0.AppImage
./SynkOS-0.9.0.AppImage
```

**Installation (Debian/Ubuntu):**
```bash
sudo dpkg -i synko_0.9.0_amd64.deb
```

### macOS

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.9.0.dmg` | ~160 MB | macOS Disk Image |

**Installation:**
1. Open the `.dmg` file (or build locally on macOS)
2. Drag `SynkOS.app` to Applications
3. First launch: Right-click → Open (bypass Gatekeeper)

### Windows

| File | Size | Description |
|------|------|-------------|
| `SynkOS.Setup.0.9.0.exe` | ~121 MB | Windows Installer |

**Installation:**
1. Run `SynkOS.Setup.0.9.0.exe` installer
2. Complete steps and launch **SynkOS**

---

## Skills

All bundled agent skills live under **`skills/`** (canonical path in this repo).

SynkOS agent skills are installed via the [skills.sh](https://www.skills.sh) CLI:

```bash
npx skills add <skill-name>
```

### Role Skills (SynkOS Core)

| Skill | Description |
|-------|-------------|
| `synkos-skill` | Base skill — orchestration, tools reference, patterns |
| `synko-dev` | Code implementation and technical delivery |
| `synko-architect` | Architecture, ADRs, and design decisions |
| `synko-qa` | Quality gates, code review, security |
| `synko-sm` | Story lifecycle and handoff orchestration |
| `synko-analyst` | Research, knowledge consolidation, wiki management |
| `synko-po` | Story validation and acceptance criteria |
| `synko-pm` | Product strategy and backlog prioritization |
| `synko-data-engineer` | Database design, RLS, migrations |
| `synko-devops` | CI/CD, Docker, monitoring, release delivery |
| `synko-ux-design-expert` | UI audits, design systems, accessibility |

### Complementary Skills

| Skill | Description |
|-------|-------------|
| `clean-code-architect` | Code review with SOLID, DRY, KISS, YAGNI |
| `impeccable` | Full product redesign and UI craft |
| `ui-ux-pro-max` | Advanced design system (50+ styles, 161 palettes) |
| `architecture-decision-records` | ADR templates and workflow |
| `owasp-top-10` | OWASP 2021 security audit and remediation |
| `dispatching-parallel-agents` | Parallel dispatch pattern for independent tasks |
| `find-skills` | Discover and install skills from the ecosystem |

### Workflow Skills

| Skill | Description |
|-------|-------------|
| `writing-plans` | Implementation plans before coding |
| `executing-plans` | Execute plans with review checkpoints |
| `brainstorming` | Multi-perspective brainstorm sessions |
| `writing-skills` | Create and evolve agent skills |
| `requesting-code-review` | How to request effective code review |
| `receiving-code-review` | How to evaluate and respond to feedback |
| `finishing-a-development-branch` | Branch finalization with tests and PR |
| `subagent-driven-development` | Spec → implement → review pipeline |

### Utility Skills

| Skill | Description |
|-------|-------------|
| `caveman` | Ultra-compressed communication (~75% token savings) |
| `caveman-review` | Compressed code review comments |
| `caveman-commit` | Terse Conventional Commits messages |
| `caveman-compress` | Compress .md files for token efficiency |
| `personal-productivity` | Time management and task prioritization |

---

## System Requirements

| Platform | Minimum | Recommended |
|----------|---------|-------------|
| Linux | Ubuntu 20.04+, glibc 2.31+ | Latest LTS |
| macOS | macOS 12+ (Monterey) | macOS 14+ |
| Windows | Windows 10/11 64-bit | Windows 11 |

**General:**
- 4GB RAM minimum (8GB recommended)
- 500MB free disk space
- Internet connection (for MCP server communication)

---

## What's New in v0.9.0

### Execution Harness (E22 + E29)
- **Context economy**: `context_resolve_tier`, `context_map_build/get/semantic`, slim pane bootstrap
- **Tool budget**: `tool_budget_*` — perfis por workspace limitam tools MCP expostas
- **Handoff protocol**: `handoff_compose`, `handoff_persist` — delegação sem transcripts
- **Gates & policy**: `gate_run_sensors`, `gate_evidence_status`, `policy_check_story_transition`
- **Lifecycle hooks**: `hook_install` / `hook_sync_events` para Claude Code + Codex CLI
- **Session traces**: `trace_list`, `trace_replay_summary` — observabilidade no vault
- **Skills atualizadas**: todas as role skills `synko-*` documentam o harness (v0.9.0)

Referência: `skills/synkos-skill/references/execution-harness.md`

### Previous (v0.8.0)
- 68+ MCP tools, trigger automation, semantic memory, session resume
- Skill system overhaul com version tracking

### Previous (v0.7.7)
- Direct Agent Pane Spawning (`pane_open_terminal`, `pane_open_browser`, `pane_open_external`)
- Browser URL State Persistence
- Local hold-to-talk Voice & Whisper Integration
- PTY Buffer & Reattach Improvements
- Bidirectionally synced stories with auto-divergence resolution

---

## Configuration

Create a `.env` file in the application directory or set environment variables:

```bash
# Optional: Custom MCP servers
MCP_CONFIG_PATH=/path/to/mcp.json
```

---

## License

Copyright (c) 2026 GG.AI Labs. All rights reserved.

---

*Built with Electron + React + TypeScript. Powered by MCP.*
