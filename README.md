# cc-spawner

[![Windows](https://img.shields.io/badge/platform-Windows%2010%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)](https://docs.microsoft.com/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Windows user environment management for Claude Code testing and development.

## Why cc-spawner?

When testing Claude Code configurations, you need **isolated environments** that don't contaminate your main setup. cc-spawner creates dedicated Windows users with:

- Clean Claude Code installations
- Isolated `.claude` configurations
- Per-user Node.js (no global conflicts)
- Automatic API key provisioning

```
┌─────────────────────────────────────────────────────────────┐
│                    ISOLATION LEVELS                          │
├──────────────┬──────────────┬──────────────┬────────────────┤
│  Same User   │  Env Var     │  Different   │   Different    │
│  Same Config │  Override    │  User        │   Machine      │
├──────────────┼──────────────┼──────────────┼────────────────┤
│  No isolation│  Config only │  Full user   │   Complete     │
│              │              │  isolation   │   isolation    │
└──────────────┴──────────────┴──────────────┴────────────────┘
                              ▲
                              │
                     cc-spawner operates here
```

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/brrhlv/cc-spawner.git
cd cc-spawner

# 2. Add your API key
cp _config/api-keys.env.example _config/api-keys.env
# Edit _config/api-keys.env with your ANTHROPIC_API_KEY

# 3. Create a test user
./spawner spawn Lab1

# 4. Switch to the new user and test
runas /user:Lab1 cmd
# Password: Spawn12345 (default)
claude
```

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `spawn` | Create a new user with Claude Code | `./spawner spawn Lab1` |
| `respawn` | Reset user (full or config-only) | `./spawner respawn Lab1 --cli` |
| `despawn` | Remove user and clean up | `./spawner despawn Lab1 --force` |
| `cospawn` | Clone config from another user | `./spawner cospawn Lab2 --from Lab1` |
| `help` | Show help message | `./spawner help` |

### Command Options

```bash
# Spawn with specific template
./spawner spawn Lab1 --template vanilla

# Spawn with custom password
./spawner spawn Lab1 --password MyPassword123

# Respawn config only (keeps user, resets .claude)
./spawner respawn Lab1 --cli

# Respawn full (deletes and recreates user)
./spawner respawn Lab1 --full

# Despawn without confirmation
./spawner despawn Lab1 --force

# Despawn without backup
./spawner despawn Lab1 --force --no-backup

# Copy another user's Claude config
./spawner cospawn Lab2 --from Lab1
```

## What Gets Installed

When you `spawn` a user, cc-spawner automatically installs:

1. **Windows User Account** - Local user with password
2. **User Profile** - Home directory at `C:\Users\<username>`
3. **nvm-windows** - Node version manager (per-user)
4. **Node.js** - LTS version via nvm
5. **Claude Code CLI** - `npm install -g @anthropic-ai/claude-code`
6. **Template Config** - `.claude` directory from selected template
7. **API Keys** - Copied from `_config/api-keys.env`

## Directory Structure

```
cc-spawner/
├── spawner              # Bash CLI wrapper (run this)
├── spawner.ps1          # PowerShell core (runs elevated)
├── config.json          # Configuration
│
├── templates/
│   ├── vanilla/         # Stock Claude Code (default)
│   │   └── .claude/
│   │       └── settings.json
│   └── README.md        # How to add templates
│
├── _config/
│   └── api-keys.env.example
│
├── docs/
│   ├── QUICKSTART.md
│   ├── TEMPLATES.md
│   └── TROUBLESHOOTING.md
│
├── dependencies/        # Cached installers (auto-downloaded)
├── backups/             # Auto-backups on despawn/respawn
└── logs/                # Operation logs
```

## Configuration

Edit `config.json` to customize defaults:

```json
{
  "defaults": {
    "template": "vanilla",
    "password": "Spawn12345",
    "nodeVersion": "22"
  },
  "templates": {
    "vanilla": {
      "description": "Stock Claude Code - no customizations",
      "path": "templates/vanilla/.claude"
    }
  }
}
```

See [docs/TEMPLATES.md](docs/TEMPLATES.md) for adding custom templates.

## Requirements

- **Windows 10/11** - Required for user management
- **Administrator privileges** - UAC prompt on first run
- **Git Bash** - For the `./spawner` wrapper (or run `spawner.ps1` directly)

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     SPAWN WORKFLOW                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ./spawner spawn Lab1                                       │
│         │                                                    │
│         ▼                                                    │
│   ┌─────────────┐                                           │
│   │ Create User │ ──► Windows local user account            │
│   └──────┬──────┘                                           │
│          ▼                                                   │
│   ┌─────────────┐                                           │
│   │ Init Profile│ ──► Login to create C:\Users\Lab1         │
│   └──────┬──────┘                                           │
│          ▼                                                   │
│   ┌─────────────┐                                           │
│   │ Install nvm │ ──► Per-user Node version manager         │
│   └──────┬──────┘                                           │
│          ▼                                                   │
│   ┌─────────────┐                                           │
│   │ Install Node│ ──► Node.js LTS via nvm                   │
│   └──────┬──────┘                                           │
│          ▼                                                   │
│   ┌─────────────┐                                           │
│   │Install Claude──► npm i -g @anthropic-ai/claude-code     │
│   └──────┬──────┘                                           │
│          ▼                                                   │
│   ┌─────────────┐                                           │
│   │ Copy Config │ ──► Template .claude + API keys           │
│   └─────────────┘                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

**Quick fixes:**

```bash
# Permission denied? Run as admin
powershell -Command "Start-Process powershell -Verb RunAs"

# User already exists?
./spawner despawn Lab1 --force
./spawner spawn Lab1

# Config corrupted? Reset just the config
./spawner respawn Lab1 --cli
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.
