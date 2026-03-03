#!/usr/bin/env sh
# Capture hook - logs what Claude Code sends to hooks
CAPTURE_DIR="${HOOKS_CAPTURE_DIR:-.test/captures}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$CAPTURE_DIR"

# Capture stdin
cat > "$CAPTURE_DIR/${TIMESTAMP}_stdin.json"

# Capture env
env | grep -E '^(CLAUDE_|HOME|PWD|USER)' | sort > "$CAPTURE_DIR/${TIMESTAMP}_env.txt"

# Return success
echo '{"decision": "allow"}'
