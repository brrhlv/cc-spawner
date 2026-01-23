# PAI Mod Template

Customized PAI framework - brrhlv's modded version.

## What's Included

- Hooks system (startup, session management)
- Skills framework support
- Agents framework support
- Bridge sync capability
- Memory system support

## What's NOT Included

- Personal identity (IDENTITY.md, TELOS)
- Pre-configured skills or agents
- Runtime profile switching (use Spawner for isolation)

## Extending

Add skills:
```
~/.claude/skills/my-skill/SKILL.md
```

Add agents:
```
~/.claude/agents/my-agent.md
```

Add hooks:
```
~/.claude/hooks/my-hook.js
```

## Isolation Model

This template does NOT use runtime profiles.

For isolation, use Spawner to create separate users:
```bash
./spawner spawn Lab1 -t pai-mod
./spawner spawn Lab2 -t cc-vanilla
```

Each spawned user has complete OS-level isolation.

## Related

- `~/Spawner/` - User environment management
- PAI documentation: https://github.com/danielmiessler/pai
