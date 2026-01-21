# Changelog

All notable changes to cc-spawner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
