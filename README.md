# Spawner

Isolated Claude Code environments with configuration sharing for Windows.

Create separate Windows users with their own Claude Code configurations, skills, and agents. Share configurations via GitHub, sync templates across users, and manage backups - perfect for testing, development, teams, and experimentation.

## What's New in v3

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

# Create with PAI framework + developer identity
.\spawner.ps1 spawn Lab2 --base pai-mod --identity developer

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
| `validate` | Validate templates | `validate pai-mod --force` |

### Admin Management (v3)

| Command | Purpose | Example |
|---------|---------|---------|
| `backup` | Backup admin's .claude | `backup --output my-backup` |
| `restore` | Restore from backup | `restore backups/admin/2025-01-23` |
| `upgrade` | Upgrade from template/git | `upgrade --from pai-mod` |

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
| `sync` | Push template to users | `sync pai-mod --to Lab1,Lab2` |
| `diff` | Compare two configs | `diff Lab1 pai-mod --detailed` |

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
.\spawner.ps1 spawn Lab1 --base pai-mod --identity developer
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
- Git (for GitHub features)
- GitHub CLI `gh` (optional, for publish command)

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
  "version": "3.0",
  "defaults": {
    "template": "cc-vanilla"
  },
  "admin": {
    "configDir": "C:\\Users\\YourUser\\.claude",
    "backupRetention": 10
  },
  "backups": {
    "adminPath": "backups/admin",
    "usersPath": "backups/users",
    "exportsPath": "exports"
  },
  "github": {
    "defaultVisibility": "private"
  },
  "security": {
    "sanitize": {
      "removeFiles": [".env", ".credentials.json"],
      "redactPatterns": ["sk-ant-api.*", "ghp_.*"]
    }
  }
}
```

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
│   ├── Admin-*.ps1      # Admin management
│   ├── User-*.ps1       # User snapshots
│   ├── Template-*.ps1   # Template syncing
│   ├── Config-*.ps1     # Diff/decompose
│   ├── Git-*.ps1        # Git integration
│   ├── GitHub-*.ps1     # GitHub sharing
│   └── templates/       # Template files
├── backups/             # Auto-backups
│   ├── admin/           # Admin backups
│   └── users/           # User snapshots
├── exports/             # Sanitized exports
├── decomposed/          # Decomposed configs
├── dependencies/        # Cached installers
└── logs/                # Operation logs
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
- [PAI Framework](https://github.com/danielmiessler/pai) by Daniel Miessler
