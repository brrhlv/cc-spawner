# MCP Server Setup Guide

Model Context Protocol (MCP) servers extend Claude Code with additional capabilities.

## Important Security Note

**43% of MCP servers have vulnerabilities** (Anthropic security research). Only add servers you trust.

## Tool Search (Automatic)

Claude Code automatically enables Tool Search when MCP tools exceed 10% of context window:
- Lazy loads 3-5 relevant tools per query (~3K tokens vs 50K+)
- No configuration needed - enabled by default
- Override with `ENABLE_TOOL_SEARCH=false` if needed

## Adding MCP Servers

### HTTP Transport (Recommended)

```bash
# GitHub integration
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

### stdio Transport

```bash
# Memory server
claude mcp add --transport stdio memory -- npx -y @modelcontextprotocol/server-memory

# Filesystem server
claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem ~/projects
```

### Windows-Specific

Windows requires a `cmd` wrapper for stdio servers:

```bash
# Database server (Windows)
claude mcp add --transport stdio db -- cmd /c npx -y @bytebase/dbhub

# Memory server (Windows)
claude mcp add --transport stdio memory -- cmd /c npx -y @modelcontextprotocol/server-memory
```

## Configuration Files

### Project Scope (.mcp.json)

Located in project root. Best for team-shared servers:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

### User Scope (~/.claude/settings.json)

For personal servers across all projects.

### Priority Order

1. `.mcp.json` (project - highest priority)
2. `~/.claude/settings.json` (user)
3. Managed settings (enterprise - lowest priority)

## Best Practices

1. **Pin package versions** when possible
2. **Never store credentials** in `.mcp.json` (use env vars)
3. **Review server code** before adding
4. **Start minimal** - add servers as needed
5. **Use project scope** for team consistency

## Troubleshooting

### Server won't start

```bash
# Check server status
claude mcp list

# Remove and re-add
claude mcp remove <server-name>
claude mcp add ...
```

### High context usage

If Tool Search triggers frequently, consider reducing active MCP servers.

## Resources

- [MCP Specification](https://modelcontextprotocol.io/)
- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp)
- [MCP Security Best Practices](https://modelcontextprotocol.io/specification/draft/basic/security_best_practices)
