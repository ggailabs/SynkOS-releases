# SynkOS Releases

> Multi-agent terminal orchestrator for AI-powered development workflows

## Latest Version: v0.7.7

**SynkOS** is the operational layer for multi-agent AI development. It integrates MCP as internal contract, squads as traceable execution units, stories as planning primitives, vault/wiki as persistent memory, and a UI for observability and operational control.

---

## Downloads

### Linux

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.7.7.AppImage` | ~150 MB | Universal Linux executable (recommended) |
| `synko_0.7.7_amd64.deb` | ~124 MB | Debian/Ubuntu installation package |

**Installation (AppImage):**
```bash
# Download and make executable
chmod +x SynkOS-0.7.7.AppImage
./SynkOS-0.7.7.AppImage
```

**Installation (Debian/Ubuntu):**
```bash
sudo dpkg -i synko_0.7.7_amd64.deb
```

### macOS

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.7.7.dmg` | ~160 MB | macOS Disk Image |

**Installation:**
1. Open the `.dmg` file (or build locally on macOS)
2. Drag `SynkOS.app` to Applications
3. First launch: Right-click → Open (bypass Gatekeeper)

### Windows

| File | Size | Description |
|------|------|-------------|
| `SynkOS.Setup.0.7.7.exe` | ~121 MB | Windows Installer |

**Installation:**
1. Run `SynkOS.Setup.0.7.7.exe` installer
2. Complete steps and launch **SynkOS**

---

## Skills

SynkOS agent skills are installed via the [skills.sh](https://www.skills.sh) CLI:

```bash
npx skills add <skill-name>
```

Available skills:

| Skill | Description |
|-------|-------------|
| `synko-dev` | General development agent |
| `synko-architect` | Architecture and design decisions |
| `synko-qa` | Quality assurance and testing |
| `synko-sm` | Scrum master and process management |
| `synko-analyst` | Requirements analysis |
| `synko-po` | Product owner and backlog management |
| `synko-pm` | Project management |
| `synko-data-engineer` | Data engineering workflows |
| `synko-devops` | DevOps and infrastructure |
| `synko-ux-design-expert` | UX design and research |
| `clean-code-architect` | Code quality and clean architecture |
| `impeccable` | Frontend design and UI polish |
| `ui-ux-pro-max` | Advanced UI/UX design system |

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

## What's New in v0.7.7

### Highlights
- **Direct Agent Pane Spawning**: Added new MCP tools (`pane_open_terminal`, `pane_open_browser`, `pane_open_external`) that allow running agents to trigger and manage visual panes in the SynkOS dashboard.
- **Browser URL State Persistence**: Solved the UI layout bug so that moving or resizing the browser pane retains the exact URL state instead of dropping back to workspace root.
- **Local hold-to-talk Voice & whisper Integration**: Added high-fidelity microphone capturing with local/Groq Whisper transcription and automated Portuguese-to-English translation.
- **PTY Buffer & Reattach Improvements**: Fixed core PTY leaks and terminal process race conditions so that multiple parallel shells open instantly and retain terminal visual buffers.

### Fixes & Stabilities
- Replaced monolithic modules with decoupled registers and dynamic message bus routers.
- Resolved memory leaks and terminal process hang-ups under core PTY modules.
- Integrated proper OAuth state parameter validation and removed all hardcoded auth secrets.
- Fixed welcome screen scroll container overflow issues and polished layout styling for high-definition displays.
- Consolidated bidirectionally synced stories across `stories.json` and `backlog.md` with auto-divergence resolution.

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
