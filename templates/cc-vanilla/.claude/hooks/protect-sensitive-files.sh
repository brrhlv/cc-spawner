#!/bin/bash
# Block edits to sensitive files - EXIT 2 = BLOCK
read -r INPUT
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

BLOCKED_PATTERNS=(".env" ".env." "secrets/" ".git/" ".pem" "credentials" ".key")

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED: Cannot edit files matching '$pattern'" >&2
    exit 2
  fi
done
exit 0
