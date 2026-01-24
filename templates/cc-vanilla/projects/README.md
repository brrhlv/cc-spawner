# Projects

This directory is your workspace for development projects.

## Getting Started

1. Create a new project folder
2. Copy `CLAUDE.md` template into your project
3. Customize with your project's commands and architecture

## MCP Servers (Optional)

The `.mcp.json` file configures project-scoped MCP servers. By default it's empty.

To add MCP servers:

```bash
# Add GitHub MCP (HTTP - recommended)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Add local server (stdio)
claude mcp add --transport stdio memory -- npx -y @modelcontextprotocol/server-memory

# Windows requires cmd wrapper for stdio
claude mcp add --transport stdio db -- cmd /c npx -y @bytebase/dbhub
```

**Note:** Tool Search is automatic when MCP tools exceed 10% of context. No configuration needed.

## Security

- Never commit `.env` files
- Use `.gitignore` to exclude sensitive data
- Review MCP server security before adding (43% have vulnerabilities)
