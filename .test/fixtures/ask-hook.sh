#!/usr/bin/env sh
# Ask hook - returns "ask" and logs all invocations to see if/how Claude re-calls
CAPTURE_DIR="${HOOKS_CAPTURE_DIR:-.test/captures}"
COUNT_FILE="$CAPTURE_DIR/ask_count"

mkdir -p "$CAPTURE_DIR"

# Increment counter
if [ -f "$COUNT_FILE" ]; then
  COUNT=$(cat "$COUNT_FILE")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNT_FILE"

# Capture stdin for this invocation
cat > "$CAPTURE_DIR/ask_invocation_${COUNT}.json"

# Log
echo "$(date -Iseconds) - Ask hook invocation #$COUNT" >> "$CAPTURE_DIR/ask_hook.log"

# Return ask using Claude's expected format
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "reason": "Invocation #$COUNT - confirm?"
}
EOF
exit 0
