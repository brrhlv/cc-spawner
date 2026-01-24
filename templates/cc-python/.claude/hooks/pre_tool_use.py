#!/usr/bin/env python3
"""
PreToolUse Hook - Validate commands before execution.

This hook runs before Bash tool calls. Use it to:
- Block dangerous commands
- Enforce coding standards
- Log command execution

Exit code 0 = allow, exit code 2 = block (stderr shown to Claude).
"""
import json
import sys
import re

# Commands that should be blocked or warned about
BLOCKED_PATTERNS = [
    (r'\brm\s+-rf\s+[/~]', "Blocking recursive delete on root or home directory"),
    (r'\bgit\s+push\s+.*--force', "Blocking force push - use --force-with-lease instead"),
    (r'\bchmod\s+777\b', "Blocking chmod 777 - too permissive"),
    (r'\bcurl\s+.*\|\s*bash', "Blocking piped curl to bash - security risk"),
]

# Commands to suggest alternatives for
SUGGESTIONS = [
    (r'\bgrep\b(?!.*\|.*rg)', "Consider using 'rg' (ripgrep) for better performance"),
    (r'\bfind\s+\S+\s+-name\b', "Consider using 'fd' or 'rg --files' for better performance"),
]

def validate_command(command: str) -> tuple[bool, str]:
    """
    Validate a bash command.
    Returns (should_block, message).
    """
    # Check blocked patterns
    for pattern, message in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, message

    return False, ""

def get_suggestions(command: str) -> list[str]:
    """Get improvement suggestions for a command."""
    suggestions = []
    for pattern, message in SUGGESTIONS:
        if re.search(pattern, command):
            suggestions.append(message)
    return suggestions

def main():
    try:
        input_data = json.load(sys.stdin)

        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        command = tool_input.get('command', '')

        # Only validate Bash commands
        if tool_name != 'Bash' or not command:
            sys.exit(0)

        # Check for blocked commands
        should_block, block_reason = validate_command(command)
        if should_block:
            print(block_reason, file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks the tool call

        # Get suggestions (non-blocking)
        suggestions = get_suggestions(command)
        if suggestions:
            # Output suggestions as JSON for Claude to consider
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": "Suggestions: " + "; ".join(suggestions)
                }
            }
            print(json.dumps(output))

        sys.exit(0)

    except json.JSONDecodeError:
        sys.exit(0)
    except Exception as e:
        print(f"PreToolUse hook error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
