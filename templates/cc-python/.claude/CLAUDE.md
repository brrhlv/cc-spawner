# Claude Code with Python Hooks

This template includes Python-based hooks following Anthropic's recommended patterns.

## Hooks Included

| Hook | Event | Purpose |
|------|-------|---------|
| `session_start.py` | SessionStart | Inject context at session start |
| `pre_tool_use.py` | PreToolUse (Bash) | Validate commands before execution |
| `post_tool_use.py` | PostToolUse (Edit/Write) | Auto-format files after edits |

## Requirements

- Python 3.10+ (installed by Spawner)
- Optional: `black` for Python formatting
- Optional: `prettier` for JS/TS/JSON formatting

## Customization

Edit hooks in `.claude/hooks/` to customize behavior:

- Add blocked command patterns in `pre_tool_use.py`
- Add formatters in `post_tool_use.py`
- Inject project context via `session_start.py`

## Hook Patterns

All hooks follow Anthropic's standard pattern:
```python
input_data = json.load(sys.stdin)  # Read hook input
# ... process ...
sys.exit(0)  # Success
sys.exit(2)  # Block with stderr message to Claude
```
