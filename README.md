# SynkOS Releases

> Multi-agent terminal orchestrator for AI-powered development workflows

## Latest Version: v0.4.5

---

## Downloads

### Linux

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.4.5.AppImage` | ~155 MB | Universal Linux executable (recommended) |
| `linux-unpacked/` | - | Extracted application directory |

**Installation (AppImage):**
```bash
chmod +x SynkOS-0.4.5.AppImage
./SynkOS-0.4.5.AppImage
```

### macOS

| File | Size | Description |
|------|------|-------------|
| `SynkOS-0.4.5.dmg` | ~160 MB | macOS Disk Image |
| `mac/SynkOS.app` | - | Extracted application bundle |

**Installation:**
1. Open the `.dmg` file
2. Drag `SynkOS.app` to Applications
3. First launch: Right-click → Open (bypass Gatekeeper)

### Windows

| File | Size | Description |
|------|------|-------------|
| `SynkOS-Setup-0.4.5.exe` | ~150 MB | Windows Installer |
| `SynkOS-0.4.5-win.zip` | ~150 MB | Portable ZIP |

**Installation:**
1. Run the installer or extract the ZIP
2. Launch `SynkOS.exe`

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

## What's New in v0.4.5

### Features
- Multi-agent pane orchestration with real-time synchronization
- Story-driven development workflow with backlog integration
- Persistent vault/wiki memory across sessions
- MCP server integration for extensible capabilities
- Role-based agent squads (dev, architect, qa, sm, analyst, po, data-engineer, ux-design-expert)

### Fixes
- Resolved UI crashes in terminal renderer
- Fixed identity injection in PTY processes
- Stabilized update workflow and sync mechanisms

### Known Issues
- Windows: Some antivirus may flag the unsigned executable
- macOS: First launch requires manual Gatekeeper bypass

---

## Configuration

Create a `.env` file in the application directory or set environment variables:

```bash
# Supabase (for cloud persistence)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Optional: Custom MCP servers
MCP_CONFIG_PATH=/path/to/mcp.json
```

---

## License

Copyright (c) 2025 GG.AI Labs. All rights reserved.
