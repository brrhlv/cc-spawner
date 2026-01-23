# Spawner

Isolated Claude Code environments with universal identity system for Windows.

Create separate Windows users with their own Claude Code configurations, skills, and agents - perfect for testing, development, and experimentation without affecting your main setup.

## Features

- **Universal Identity System** - Apply skill sets (developer, researcher, learner, auditor) to any base template
- **Isolated Environments** - Each user has their own Node.js, npm, and Claude Code installation
- **Template-Based** - Start from stock Claude Code or PAI framework
- **Project Copying** - Clone projects into new environments
- **Automatic Backups** - Backup on respawn/despawn operations

## Quick Start

```powershell
# Run as Administrator

# Create a vanilla Claude Code user
.\spawner.ps1 spawn Lab1

# Create with PAI framework + developer identity
.\spawner.ps1 spawn Lab2 --base pai-mod --identity developer

# Create with researcher skills
.\spawner.ps1 spawn Lab3 --base cc-vanilla --identity researcher

# Reset just the .claude config (keep user)
.\spawner.ps1 respawn Lab1 --cli

# Delete a user completely
.\spawner.ps1 despawn Lab1 --force
```

## Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `spawn` | Create new user environment | `spawn Lab1 --identity developer` |
| `respawn` | Reset user (full or --cli) | `respawn Lab1 --cli` |
| `despawn` | Delete user and data | `despawn Lab1 --force` |
| `cospawn` | Copy from another user | `cospawn Lab2 --from Lab1` |
| `validate` | Validate templates | `validate pai-mod --force` |

## Base Templates

| Template | Description |
|----------|-------------|
| `cc-vanilla` | Stock Claude Code - no framework (default) |
| `pai-vanilla` | Minimal PAI skeleton - basic structure |
| `pai-mod` | PAI with hooks framework |

## Identities

Identities are **universal** - they work with any base template. An identity adds skills, agents, and hooks to whatever base you choose.

| Identity | Focus | Skills | Agents |
|----------|-------|--------|--------|
| `developer` | Code quality | code-reviewer, tdd, api-design | architect |
| `researcher` | Information | search, summarize | research-analyst |
| `learner` | Education | explain, tutor | - |
| `auditor` | Security (read-only) | security-scan | - |

```powershell
# Stock Claude + developer skills
.\spawner.ps1 spawn Lab1 --base cc-vanilla --identity developer

# PAI framework + researcher tools
.\spawner.ps1 spawn Lab2 --base pai-mod --identity researcher
```

## Installation

### Requirements
- Windows 10/11
- Administrator privileges
- Git Bash (optional, for bash wrapper)

### Setup

1. Clone or download this repository
2. Create `.passwords.json` (gitignored):
```json
{
  "defaults": { "password": "YourDefaultPass123" },
  "categories": {
    "lab": "LabPass123",
    "dev": "DevPass123"
  }
}
```

3. Create `_config/api-keys.env`:
```
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
```

4. Run as Administrator:
```powershell
.\spawner.ps1 spawn Lab1
```

## Configuration

### config.json

```json
{
  "defaults": {
    "template": "cc-vanilla"
  },
  "templates": { ... },
  "identities": {
    "available": ["developer", "researcher", "learner", "auditor"]
  },
  "projects": {
    "myproject": "C:\\path\\to\\project"
  }
}
```

### Password Categories

Users are categorized by name prefix:
- `Lab*` → lab category
- `Dev*` → dev category
- Others → default password

## Directory Structure

```
Spawner/
├── spawner.ps1          # Main PowerShell script
├── config.json          # Configuration
├── .passwords.json      # Passwords (gitignored)
├── manifest.json        # User registry
├── identities/          # Universal identities
│   ├── developer/
│   ├── researcher/
│   ├── learner/
│   └── auditor/
├── templates/           # Base templates
│   ├── cc-vanilla/
│   ├── pai-vanilla/
│   └── pai-mod/
├── lib/                 # Helper scripts
├── dependencies/        # Cached installers
├── backups/             # Auto-backups
└── logs/                # Operation logs
```

## Creating Custom Identities

1. Create folder: `identities/my-identity/`
2. Add `IDENTITY.md` with personality/instructions
3. Add skills in `skills/skill-name/SKILL.md`
4. Add agents in `agents/agent-name.md`
5. Optional: `settings.patch.json` for permissions

See `identities/README.md` for details.

## How It Works

**spawn** creates:
1. Windows local user account
2. User profile directory
3. Portable Node.js installation (per-user)
4. Claude Code CLI via npm
5. Template .claude directory
6. Identity merge (if specified)
7. Git configuration
8. API key setup

**respawn --cli** resets just the .claude directory without recreating the user.

**despawn** removes the user, home directory, and manifest entry.

## Security Notes

- `.passwords.json` is gitignored - never commit passwords
- API keys stored in `_config/api-keys.env` (gitignored)
- Each spawned user is isolated from others
- Validate API key format before use

## Contributing

### Adding Identities
See `identities/README.md` for the identity structure.

### Adding Templates
1. Create `templates/my-template/.claude/`
2. Add `settings.json` with proper schema
3. Register in `config.json` templates section
4. Run `.\spawner.ps1 validate my-template`

## License

MIT

## Credits

- [Claude Code](https://github.com/anthropics/claude-code) by Anthropic
- [PAI Framework](https://github.com/danielmiessler/pai) by Daniel Miessler
