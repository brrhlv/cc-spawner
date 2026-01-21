# Contributing to cc-spawner

Thank you for your interest in contributing to cc-spawner!

## How to Contribute

### Reporting Bugs

1. Check existing [issues](https://github.com/brrhlv/cc-spawner/issues) first
2. Use the bug report template
3. Include:
   - Windows version
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant log output from `logs/`

### Suggesting Features

1. Check existing issues for similar requests
2. Use the feature request template
3. Describe the use case and expected behavior

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test thoroughly:
   - Spawn a new user
   - Verify Claude Code works
   - Test respawn and despawn
5. Commit with clear messages
6. Push and create a PR

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/cc-spawner.git
cd cc-spawner

# Create test API keys
cp _config/api-keys.env.example _config/api-keys.env
# Add your ANTHROPIC_API_KEY

# Test spawn
./spawner spawn TestUser

# Test despawn
./spawner despawn TestUser --force
```

## Code Style

### PowerShell (spawner.ps1)
- Use `Write-Log` for all output
- Handle errors with try/catch
- Add comments for complex logic
- Follow existing naming conventions

### Bash (spawner wrapper)
- Keep it minimal - just invoke PowerShell
- Handle argument quoting properly

## Adding Templates

See [templates/README.md](templates/README.md) for template guidelines.

Templates should:
- Be minimal and focused
- Not include secrets or personal data
- Include a clear description in config.json

## Questions?

Open an issue with the "question" label.
