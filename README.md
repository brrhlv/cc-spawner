# Spawner

Isolated Claude Code environments with configuration sharing for Windows.

Create separate Windows users with their own Claude Code configurations, skills, and agents. Share configurations via GitHub, sync templates across users, and manage backups - perfect for testing, development, teams, and experimentation.

## What's New in v4

- **Native Claude Code Installation** - No more npm/Node.js dependency
- **Python Hooks Support** - Anthropic-recommended Python hooks pattern
- **Faster Downloads** - Optimized binary caching
- **Cross-Platform Ready** - Path structure compatible with Linux/macOS/WSL

### v3 Features (still available)

- **Admin Backup/Restore** - Backup and restore your main .claude configuration
- **Export & Share** - Sanitized exports safe for public sharing (secrets removed)
- **GitHub Integration** - Publish templates to GitHub, spawn from URLs
- **Template Syncing** - Push/pull configurations between templates and users
- **Config Decomposition** - Separate configs into reusable base/identity/project layers

## Quick Start

```powershell
# Run as Administrator

# Create a vanilla Claude Code user
.\spawner.ps1 spawn Lab1

# Create with Python hooks + developer identity
.\spawner.ps1 spawn Lab2 --template cc-python --identity developer

# Backup your admin config
.\spawner.ps1 backup

# Export a user's config for sharing
.\spawner.ps1 export Lab1 --output Lab1-share.zip

# Spawn from a GitHub template
.\spawner.ps1 clone https://github.com/user/cc-template Lab3
```

## Commands

### User Management

| Command | Purpose | Example |
|---------|---------|---------|
| `spawn` | Create new user environment | `spawn Lab1 --identity developer` |
| `respawn` | Reset user (full or --cli) | `respawn Lab1 --cli` |
| `despawn` | Delete user and data | `despawn Lab1 --force` |
| `cospawn` | Copy from another user | `cospawn Lab2 --from Lab1` |
| `validate` | Validate templates | `validate cc-python --fix` |

### Admin Management (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `backup` | Backup admin's .claude | `backup --output my-backup` |
| `restore` | Restore from backup | `restore backups/admin/2025-01-23` |
| `upgrade` | Upgrade from template/git | `upgrade --from cc-python` |

### User Snapshots (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `snapshot` | Save user's complete state | `snapshot Lab1` |
| `export` | Export sanitized for sharing | `export Lab1 --output Lab1.zip` |
| `import` | Import to user | `import Lab1.zip Lab2` |

### Template Syncing (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `promote` | Save user as template | `promote Lab1 --as my-template` |
| `sync` | Push template to users | `sync cc-python --to Lab1,Lab2` |
| `diff` | Compare two configs | `diff Lab1 cc-python --detailed` |

### Git Integration (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `repo init` | Initialize git for template | `repo init my-template` |
| `repo status` | Check template git status | `repo status my-template` |
| `repo commit` | Commit template changes | `repo commit my-template -m "v1.1"` |

### GitHub Sharing (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `publish` | Push template to GitHub | `publish my-template --repo user/repo` |
| `clone` | Spawn from GitHub URL | `clone https://github.com/user/repo Lab5` |

### Decomposition (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `decompose` | Extract config layers | `decompose Lab1` |

## Sharing Workflow

```powershell
# 1. Test and refine config in a Lab user
.\spawner.ps1 spawn Lab1 --template cc-python --identity developer
# ... customize, test, iterate ...

# 2. Promote to template
.\spawner.ps1 promote Lab1 --as my-setup

# 3. Version control it
.\spawner.ps1 repo init my-setup
.\spawner.ps1 repo commit my-setup -m "Initial version"

# 4. Publish to GitHub
.\spawner.ps1 publish my-setup --repo myuser/claude-template

# 5. Share the link - others can spawn from it
.\spawner.ps1 clone https://github.com/myuser/claude-template Lab1
```

## Base Templates

| Template | Description | Python |
|----------|-------------|--------|
| `cc-vanilla` | Stock Claude Code - minimal, no hooks (default) | No |
| `cc-python` | Claude Code with Python hooks (Anthropic patterns) | Yes |

### Legacy Templates (npm-based, deprecated)

| Template | Description |
|----------|-------------|
| `cc-vanilla-legacy` | Stock Claude Code (npm installation) |

### Template Details

**cc-vanilla** (default) - Minimal setup:
- No hooks, no Python required
- Clean slate for customization
- Fastest spawn time

**cc-python** - Python hooks enabled (Anthropic patterns):
- `session_start.py` - Inject context at session start
- `pre_tool_use.py` - Validate/block dangerous commands
- `post_tool_use.py` - Auto-format files after edits
- Requires Python (auto-installed by Spawner)

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

# Python hooks + researcher tools
.\spawner.ps1 spawn Lab2 --template cc-python --identity researcher
```

## Installation

### Requirements
- Windows 10/11
- Administrator privileges
- Internet connection (first-time dependency download)
- Git (for GitHub features)
- GitHub CLI `gh` (optional, for publish command)

**No Node.js required** - Spawner downloads Claude Code native binary and Python embeddable automatically.

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
  "version": "4.0",
  "defaults": {
    "template": "cc-vanilla"
  },
  "dependencies": {
    "claudeCode": {
      "version": "latest",
      "channel": "stable"
    },
    "python": {
      "version": "3.12.8",
      "embeddable": true
    }
  },
  "admin": {
    "configDir": "C:\\Users\\YourUser\\.claude",
    "backupRetention": 10
  },
  "templates": {
    "cc-vanilla": { "requiresPython": false },
    "cc-python": { "requiresPython": true }
  }
}
```

## Directory Structure

```
Spawner/
├── spawner.ps1          # Main PowerShell script
├── config.json          # Configuration (v4)
├── .passwords.json      # Passwords (gitignored)
├── manifest.json        # User registry
├── identities/          # Universal identities
│   ├── developer/
│   ├── researcher/
│   ├── learner/
│   └── auditor/
├── templates/           # Base templates
│   ├── cc-vanilla/      # Default - minimal
│   └── cc-python/       # Python hooks
├── lib/                 # Helper scripts
├── backups/             # Auto-backups
├── exports/             # Sanitized exports
├── dependencies/        # Cached binaries
│   ├── claude-code/     # Native Claude binary
│   └── python/          # Python embeddable
└── logs/                # Operation logs
```

### Per-User Installation

```
C:\Users\{Username}\
├── .local\
│   ├── bin\claude.exe   # Claude Code native
│   └── share\claude\    # Version data
├── .python\             # Python (if template needs it)
│   ├── python.exe
│   └── Scripts\pip.exe
├── .claude\             # Configuration
│   ├── settings.json
│   └── hooks\           # Python hooks (cc-python)
└── projects\            # Project scaffold
```

## Security

### Export Sanitization

When you run `export` or `publish`, configs are automatically sanitized:

1. **Removed**: `.env`, `.credentials.json`, `api-keys.env`, session data
2. **Redacted**: API keys (Anthropic, GitHub, OpenAI, Slack patterns)
3. **Replaced**: Hardcoded paths → `{USER_HOME}` placeholders
4. **Validated**: Final check ensures no secrets remain

```powershell
# Safe to share publicly
.\spawner.ps1 export Lab1 --output Lab1-public.zip
```

### What's Never Shared
- API keys and credentials
- Session history and cache
- Local paths and user data
- Passwords and tokens

## MCP Servers

MCP (Model Context Protocol) servers are **not bundled by default** due to security concerns (43% have vulnerabilities per Anthropic research). Add them as needed:

```bash
# HTTP transport (recommended)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# stdio transport
claude mcp add --transport stdio memory -- npx -y @modelcontextprotocol/server-memory

# Windows requires cmd wrapper for stdio
claude mcp add --transport stdio db -- cmd /c npx -y @bytebase/dbhub
```

**Tool Search** is automatic - when MCP tools exceed 10% of context, Claude lazy-loads 3-5 relevant tools per query. No configuration needed.

See `docs/MCP-SETUP.md` for detailed setup guide.

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
3. Claude Code native binary (`~/.local/bin/claude.exe`)
4. Python embeddable (if template requires hooks)
5. Template .claude directory
6. Identity merge (if specified)
7. Git configuration
8. User PATH setup (`.local/bin`, `.python` if needed)
9. API key setup

**export** sanitizes:
1. Copies .claude to temp directory
2. Removes secret files
3. Redacts inline secrets
4. Replaces hardcoded paths
5. Validates no secrets remain
6. Creates zip archive

**publish** to GitHub:
1. Validates template has git
2. Runs security check
3. Creates/updates GitHub repo
4. Pushes with auto-generated README

## License

MIT

## Credits

- [Claude Code](https://github.com/anthropics/claude-code) by Anthropic
