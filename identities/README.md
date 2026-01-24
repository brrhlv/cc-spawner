# Universal Identities

Identities define WHO Claude is (skills, personality, agents) - independent of the base template.

## Key Concept

**Identities work with ANY base template.** Python hooks come from the base template (cc-python), not the identity.

## Available Identities

| Identity | Focus | Skills | Agents |
|----------|-------|--------|--------|
| `developer` | Code quality | code-reviewer, tdd, api-design | architect |
| `researcher` | Information gathering | search, summarize | research-analyst |
| `learner` | Education | explain, tutor | - |
| `auditor` | Security (read-only) | security-scan | - |

## Usage

```bash
# Stock Claude Code + developer identity
spawner spawn Lab1 --base cc-vanilla --identity developer

# Python hooks + researcher identity
spawner spawn Lab2 --base cc-python --identity researcher

# Minimal setup (identity optional)
spawner spawn Admin --base cc-vanilla
```

## Identity Structure

```
identities/
└── developer/
    ├── IDENTITY.md          # Appended to CLAUDE.md
    ├── skills/              # Copied to user's skills/
    │   ├── code-reviewer/
    │   └── tdd/
    ├── agents/              # Copied to user's agents/
    │   └── architect.md
    ├── hooks/               # Copied to user's hooks/
    │   └── pre-commit-lint.js
    └── settings.patch.json  # Merged into settings.json
```

## Creating Custom Identities

1. Create folder: `identities/my-identity/`
2. Add `IDENTITY.md` with personality and instructions
3. Add skills in `skills/skill-name/SKILL.md`
4. Add agents in `agents/agent-name.md`
5. Add optional hooks and settings.patch.json

## Merge Behavior

When spawning with `--identity`:
1. `IDENTITY.md` content is appended to CLAUDE.md
2. Skills folder contents are copied (merged)
3. Agents folder contents are copied (merged)
4. Hooks folder contents are copied (merged)
5. settings.patch.json is merged into settings.json
