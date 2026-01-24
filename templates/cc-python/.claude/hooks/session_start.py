#!/usr/bin/env python3
"""
SessionStart Hook - Inject context at session start.

This hook runs when Claude Code starts a new session or resumes.
Use it to load environment context, project info, or custom instructions.

Output to stdout is added to Claude's context.
Exit code 0 = success, non-zero = error (shown to user).
"""
import json
import sys
import os
from datetime import datetime

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)

        # Extract session info
        session_id = input_data.get('session_id', 'unknown')
        source = input_data.get('source', 'startup')  # startup, resume, clear, compact
        cwd = input_data.get('cwd', os.getcwd())

        # Build context to inject
        context_parts = []

        # Add timestamp
        context_parts.append(f"Session started: {datetime.now().strftime('%Y-%m-%d %H:%M')}")

        # Add working directory info
        context_parts.append(f"Working directory: {cwd}")

        # Check for project-specific context file
        project_context = os.path.join(cwd, '.claude', 'CONTEXT.md')
        if os.path.exists(project_context):
            with open(project_context, 'r', encoding='utf-8') as f:
                context_parts.append(f"Project context:\n{f.read()}")

        # Output context (will be injected into Claude's context)
        if context_parts:
            print('\n'.join(context_parts))

        sys.exit(0)

    except json.JSONDecodeError:
        # No input or invalid JSON - just exit cleanly
        sys.exit(0)
    except Exception as e:
        print(f"SessionStart hook error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
