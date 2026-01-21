# Templates Guide

Templates define the initial `.claude` configuration for spawned users.

## Understanding Templates

When you spawn a user, cc-spawner copies a template's `.claude` directory to the new user's home folder. This gives them a pre-configured Claude Code environment.

```
Template Location                    User Location
templates/vanilla/.claude/     →     C:\Users\Lab1\.claude\
├── settings.json              →     ├── settings.json
├── CLAUDE.md (if present)     →     ├── CLAUDE.md
└── ...                        →     └── ...
```

## Included Templates

### vanilla (Default)

Stock Claude Code with no customizations:

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {}
}
```

Use this for:
- Testing Claude Code defaults
- Clean-slate experiments
- Baseline comparisons

## Creating Custom Templates

### Step 1: Create Template Directory

```bash
mkdir -p templates/my-template/.claude
```

### Step 2: Add Configuration Files

At minimum, create `settings.json`:

```bash
cat > templates/my-template/.claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(git:*)"
    ],
    "deny": []
  },
  "hooks": {}
}
EOF
```

### Step 3: Register in config.json

Add your template to `config.json`:

```json
{
  "templates": {
    "vanilla": { ... },
    "my-template": {
      "description": "My custom template with npm and git permissions",
      "path": "templates/my-template/.claude"
    }
  }
}
```

### Step 4: Use Your Template

```bash
./spawner spawn Lab1 --template my-template
```

## Template Contents

A template can include any files that belong in `.claude/`:

| File/Folder | Purpose |
|-------------|---------|
| `settings.json` | **Required** - Permissions and hooks config |
| `CLAUDE.md` | Default instructions for Claude |
| `commands/` | Custom slash commands |
| `hooks/` | Event-triggered scripts |
| `skills/` | Skill definitions |
| `agents/` | Agent definitions |

## Example: Developer Template

```
templates/developer/.claude/
├── settings.json
├── CLAUDE.md
└── commands/
    └── commit.md
```

**settings.json:**
```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(git:*)",
      "Bash(node:*)"
    ],
    "deny": []
  }
}
```

**CLAUDE.md:**
```markdown
# Developer Environment

This is a development environment. You have access to:
- npm commands
- git commands
- node execution

Follow best practices for code quality.
```

## Tips

1. **Keep templates minimal** - Only include what's necessary
2. **No secrets** - Never put API keys in templates
3. **Test first** - Spawn a test user before committing
4. **Document** - Add a description in config.json
5. **Version control** - Commit templates to track changes

## Template Inheritance

cc-spawner doesn't support template inheritance, but you can:

1. Create a base template manually
2. Use `cospawn` to copy and modify:
   ```bash
   ./spawner spawn Lab1 --template base
   # Make changes to Lab1's config
   ./spawner cospawn Lab2 --from Lab1
   ```
