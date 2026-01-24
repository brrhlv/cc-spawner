#!/bin/bash
# Block dangerous bash commands - EXIT 2 = BLOCK
read -r INPUT
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

DANGEROUS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
  "git push --force"
  "git push -f"
  "git reset --hard"
  "chmod 777"
  "DROP DATABASE"
  "DROP TABLE"
  "> /dev/sda"
)

for pattern in "${DANGEROUS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "BLOCKED: Dangerous command detected: $pattern" >&2
    exit 2
  fi
done
exit 0
