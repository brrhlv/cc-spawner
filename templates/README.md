# Templates

Templates define the initial `.claude` directory structure for spawned users.

## Included Templates

### vanilla
Stock Claude Code configuration with no customizations:
- Empty permissions (no pre-approved tools)
- No hooks
- No skills or agents

This is the default template - a clean slate for testing.

## Adding Custom Templates

1. Create a new directory under `templates/`:
   ```
   templates/
   └── my-template/
       └── .claude/
           ├── settings.json
           ├── CLAUDE.md (optional)
           └── ... (any other .claude files)
   ```

2. Add the template to `config.json`:
   ```json
   {
     "templates": {
       "my-template": {
         "description": "My custom template description",
         "path": "templates/my-template/.claude"
       }
     }
   }
   ```

3. Use it when spawning:
   ```bash
   ./spawner spawn Lab5 --template my-template
   ```

## Template Structure

A template directory should mirror what you want in the user's `~/.claude/`:

```
templates/my-template/.claude/
├── settings.json      # Required: Claude Code settings
├── CLAUDE.md          # Optional: Default instructions
├── commands/          # Optional: Custom slash commands
├── hooks/             # Optional: Event hooks
├── skills/            # Optional: Skill definitions
└── agents/            # Optional: Agent definitions
```

## Tips

- Keep templates minimal - only include what's needed
- Don't include secrets or API keys in templates
- Use `_config/api-keys.env` for credentials (copied at spawn time)
- Test templates by spawning a test user before committing
