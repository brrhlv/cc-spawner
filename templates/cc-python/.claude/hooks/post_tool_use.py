#!/usr/bin/env python3
"""
PostToolUse Hook - Run actions after file edits.

This hook runs after Edit or Write tool calls succeed.
Use it for auto-formatting, linting, or notifications.

Exit code 0 = success, exit code 2 = provide feedback to Claude.
"""
import json
import sys
import os
import subprocess

# File extensions and their formatters
FORMATTERS = {
    '.py': ['python3', '-m', 'black', '--quiet'],
    '.js': ['npx', 'prettier', '--write'],
    '.ts': ['npx', 'prettier', '--write'],
    '.json': ['npx', 'prettier', '--write'],
    '.md': None,  # Custom markdown formatting below
}

def format_markdown(file_path: str) -> bool:
    """Basic markdown formatting - fix excessive blank lines."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix excessive blank lines (more than 2)
        import re
        formatted = re.sub(r'\n{3,}', '\n\n', content)

        if formatted != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(formatted)
            return True
        return False
    except Exception:
        return False

def run_formatter(file_path: str) -> tuple[bool, str]:
    """
    Run appropriate formatter for file type.
    Returns (success, message).
    """
    _, ext = os.path.splitext(file_path)
    ext = ext.lower()

    if ext not in FORMATTERS:
        return True, ""

    formatter = FORMATTERS[ext]

    # Special handling for markdown
    if formatter is None and ext == '.md':
        if format_markdown(file_path):
            return True, f"Formatted {os.path.basename(file_path)}"
        return True, ""

    # Check if formatter is available
    if formatter:
        try:
            cmd = formatter + [file_path]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                return True, f"Formatted {os.path.basename(file_path)}"
            else:
                # Formatter not available or failed - not a blocking error
                return True, ""
        except (subprocess.TimeoutExpired, FileNotFoundError):
            # Formatter not available - silently continue
            return True, ""

    return True, ""

def main():
    try:
        input_data = json.load(sys.stdin)

        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        tool_response = input_data.get('tool_response', {})

        # Only process Edit/Write operations
        if tool_name not in ('Edit', 'Write'):
            sys.exit(0)

        # Get file path
        file_path = tool_input.get('file_path', '')
        if not file_path or not os.path.exists(file_path):
            sys.exit(0)

        # Run formatter
        success, message = run_formatter(file_path)

        if message:
            print(message)

        sys.exit(0)

    except json.JSONDecodeError:
        sys.exit(0)
    except Exception as e:
        print(f"PostToolUse hook error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
