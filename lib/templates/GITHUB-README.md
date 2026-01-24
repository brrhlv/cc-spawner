# {TEMPLATE_NAME}

A Claude Code configuration template for [Spawner](https://github.com/brrhlv/cc-spawner).

## Quick Start

### Using Spawner (Recommended)

```powershell
# Clone directly to a new user
spawner clone https://github.com/{REPO} <username>

# Or clone to existing user
spawner clone https://github.com/{REPO} Lab1
```

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/{REPO}.git
   ```

2. Copy the `.claude` directory to your user profile:
   ```powershell
   Copy-Item -Path ".\.claude" -Destination "C:\Users\<username>\.claude" -Recurse
   ```

3. Create your API key file:
   ```powershell
   # Create C:\Users\<username>\.claude\.env with:
   ANTHROPIC_API_KEY=sk-ant-api...
   ```

4. Replace any `{USER_HOME}` placeholders with your actual home path.

## What's Included

### Configuration
- `settings.json` - Claude Code settings and permissions
- `CLAUDE.md` - AI instructions and context

### Skills
Custom skills that extend Claude's capabilities.

### Agents
Specialized agents for specific tasks.

### Hooks
Event-driven automation scripts.

## Customization

After installation, you can customize:

1. **Settings**: Edit `.claude/settings.json`
2. **Instructions**: Modify `.claude/CLAUDE.md`
3. **Skills**: Add/remove from `.claude/skills/`
4. **Hooks**: Configure in `.claude/hooks/`

## Security Notes

This template has been sanitized:
- No API keys or credentials
- No session data or cache
- User paths replaced with `{USER_HOME}` placeholder

You must provide your own:
- Anthropic API key (`.env`)
- Any other service credentials

## Requirements

- Windows 10/11
- [Claude Code CLI](https://www.npmjs.com/package/@anthropic-ai/claude-code)
- [Spawner](https://github.com/brrhlv/cc-spawner) (optional but recommended)

## License

MIT License - See LICENSE file.

---

*Published on {DATE} with [Spawner v3](https://github.com/brrhlv/cc-spawner)*
