# Changelog

All notable changes to cc-spawner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-01-23

### Added

#### Admin Management
- `backup` command - Backup admin's .claude directory with optional secret inclusion
- `restore` command - Restore admin config from backup with merge support
- `upgrade` command - Upgrade admin config from template or git URL

#### User Snapshots
- `snapshot` command - Create full snapshot of user's .claude state
- `export` command - Export sanitized config safe for public sharing
- `import` command - Import snapshot/export to new or existing user
- Core sanitization pipeline that removes secrets, redacts patterns, replaces paths

#### Template Syncing
- `promote` command - Save user's .claude as a reusable template
- `sync` command - Push template to users or pull from user to template
- `diff` command - Compare two configs with detailed file-level differences

#### Git Integration
- `repo init` - Initialize git repository for a template
- `repo status` - Check git status of template
- `repo commit` - Commit changes to template repository
- Template .gitignore with security-focused defaults

#### GitHub Sharing
- `publish` command - Push template to GitHub (public or private)
- `clone` command - Spawn new user directly from GitHub URL
- Auto-generated README for published templates
- Security validation before publishing

#### Decomposition
- `decompose` command - Extract base/identity/project layers from user config
- `compose` command - Recompose layers into target user
- Layer separation: base (settings), identity (skills/agents), project (TELOS/memory)

### Changed
- Version bump to 3.0
- config.json restructured with new sections: admin, backups, git, github, sync, security
- Help output reorganized by feature category

### Security
- Sanitization pipeline validates no secrets remain before export/publish
- Redact patterns for API keys: Anthropic, GitHub, OpenAI, Slack
- Path replacement converts hardcoded paths to `{USER_HOME}` placeholders
- Auto-backup before destructive operations (restore, upgrade)

## [2.0.0] - 2025-01-21

### Added
- Initial public release
- `spawn` command - Create new Windows users with Claude Code
- `respawn` command - Reset users (full or config-only with `--cli`)
- `despawn` command - Remove users with optional backup
- `cospawn` command - Clone configuration from another user
- Template system for customizable `.claude` configurations
- Automatic Node.js installation via nvm-windows (per-user)
- Automatic Claude Code CLI installation
- API key provisioning from `_config/api-keys.env`
- Automatic backups on despawn/respawn
- Operation logging to `logs/` directory
- User registry tracking in `manifest.json`

### Templates
- `vanilla` - Stock Claude Code with no customizations

### Documentation
- Comprehensive README with usage examples
- Quick start guide
- Template creation guide
- Troubleshooting guide
