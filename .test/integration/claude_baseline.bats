#!/usr/bin/env bats

# =============================================================================
# Exploratory tests: Claude Code native hook behavior
#
# These tests explore how Claude Code invokes hooks WITHOUT hooks-dispatch.
# Goal: Understand the protocol before building our dispatcher.
# =============================================================================

load '../bats/bats-support/load'
load '../bats/bats-assert/load'

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR

  # Where our test hook will log what it receives
  export HOOK_LOG="$TEST_TEMP_DIR/hook.log"
  export HOOK_STDIN="$TEST_TEMP_DIR/hook.stdin"
  export HOOK_ENV="$TEST_TEMP_DIR/hook.env"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

# =============================================================================
# Test hook script that captures everything for analysis
# =============================================================================

create_capture_hook() {
  local hook_path="$1"
  cat > "$hook_path" << 'HOOK'
#!/usr/bin/env sh
# Capture hook - logs everything it receives for analysis

# Log invocation
echo "=== Hook invoked at $(date -Iseconds) ===" >> "$HOOK_LOG"

# Capture stdin
cat > "$HOOK_STDIN"
echo "Stdin captured to $HOOK_STDIN" >> "$HOOK_LOG"

# Capture environment variables
env | grep -E '^(CLAUDE_|HOME|PWD|PATH)' | sort >> "$HOOK_ENV"

# Return success with allow
echo '{"decision": "allow"}'
exit 0
HOOK
  chmod +x "$hook_path"
}

# =============================================================================
# Simulate what Claude Code sends to SessionStart hooks
# Based on docs/research/claude-code-hooks.md
# =============================================================================

simulate_claude_session_start() {
  cat << EOF
{
  "session_id": "test-$(date +%s)",
  "transcript_path": "/tmp/test-transcript.jsonl",
  "cwd": "$(pwd)",
  "hook_event_name": "SessionStart"
}
EOF
}

# =============================================================================
# Tests
# =============================================================================

@test "capture hook receives JSON on stdin" {
  create_capture_hook "$TEST_TEMP_DIR/hook.sh"

  # Simulate Claude Code calling our hook
  simulate_claude_session_start | "$TEST_TEMP_DIR/hook.sh"

  # Verify stdin was captured
  assert [ -f "$HOOK_STDIN" ]

  # Verify it's valid JSON
  run jq '.' "$HOOK_STDIN"
  assert_success
}

@test "capture hook stdin contains session_id" {
  create_capture_hook "$TEST_TEMP_DIR/hook.sh"
  simulate_claude_session_start | "$TEST_TEMP_DIR/hook.sh"

  run jq -r '.session_id' "$HOOK_STDIN"
  assert_success
  assert [ -n "$output" ]
  assert [ "$output" != "null" ]
}

@test "capture hook stdin contains hook_event_name" {
  create_capture_hook "$TEST_TEMP_DIR/hook.sh"
  simulate_claude_session_start | "$TEST_TEMP_DIR/hook.sh"

  run jq -r '.hook_event_name' "$HOOK_STDIN"
  assert_success
  assert_equal "$output" "SessionStart"
}

@test "capture hook stdin contains cwd" {
  create_capture_hook "$TEST_TEMP_DIR/hook.sh"
  simulate_claude_session_start | "$TEST_TEMP_DIR/hook.sh"

  run jq -r '.cwd' "$HOOK_STDIN"
  assert_success
  assert [ -n "$output" ]
}

@test "hook returning allow JSON exits successfully" {
  create_capture_hook "$TEST_TEMP_DIR/hook.sh"

  run sh -c "simulate_claude_session_start | '$TEST_TEMP_DIR/hook.sh'"
  # Note: need to source the function or inline it

  run sh -c "echo '{}' | '$TEST_TEMP_DIR/hook.sh'"
  assert_success

  # Check output is valid JSON with decision
  decision=$(echo "$output" | jq -r '.decision')
  assert_equal "$decision" "allow"
}

@test "hook returning deny JSON exits successfully but blocks" {
  # Create a hook that denies
  cat > "$TEST_TEMP_DIR/deny_hook.sh" << 'HOOK'
#!/usr/bin/env sh
cat > /dev/null  # consume stdin
echo '{"decision": "deny", "reason": "Test denial"}'
exit 0
HOOK
  chmod +x "$TEST_TEMP_DIR/deny_hook.sh"

  run "$TEST_TEMP_DIR/deny_hook.sh" < /dev/null
  assert_success

  decision=$(echo "$output" | jq -r '.decision')
  assert_equal "$decision" "deny"

  reason=$(echo "$output" | jq -r '.reason')
  assert_equal "$reason" "Test denial"
}

@test "hook exit code 2 signals blocking error" {
  cat > "$TEST_TEMP_DIR/error_hook.sh" << 'HOOK'
#!/usr/bin/env sh
echo "Something went wrong" >&2
exit 2
HOOK
  chmod +x "$TEST_TEMP_DIR/error_hook.sh"

  run "$TEST_TEMP_DIR/error_hook.sh"
  assert_failure 2
}

# =============================================================================
# "Ask" decision flow exploration
# =============================================================================

@test "hook can return ask decision with reason" {
  cat > "$TEST_TEMP_DIR/ask_hook.sh" << 'HOOK'
#!/usr/bin/env sh
cat > /dev/null  # consume stdin
echo '{"decision": "ask", "reason": "Confirm dangerous operation?"}'
exit 0
HOOK
  chmod +x "$TEST_TEMP_DIR/ask_hook.sh"

  run "$TEST_TEMP_DIR/ask_hook.sh" < /dev/null
  assert_success

  decision=$(echo "$output" | jq -r '.decision')
  assert_equal "$decision" "ask"

  reason=$(echo "$output" | jq -r '.reason')
  assert_equal "$reason" "Confirm dangerous operation?"
}

@test "ask hook that tracks invocation count" {
  # This hook tracks how many times it's been called
  # If Claude re-invokes after user approval, we'd see count > 1
  cat > "$TEST_TEMP_DIR/counting_ask_hook.sh" << HOOK
#!/usr/bin/env sh
COUNT_FILE="$TEST_TEMP_DIR/invocation_count"
STDIN_DIR="$TEST_TEMP_DIR/stdin_captures"

mkdir -p "\$STDIN_DIR"

# Increment counter
if [ -f "\$COUNT_FILE" ]; then
  COUNT=\$(cat "\$COUNT_FILE")
  COUNT=\$((COUNT + 1))
else
  COUNT=1
fi
echo "\$COUNT" > "\$COUNT_FILE"

# Capture this invocation's stdin
cat > "\$STDIN_DIR/invocation_\${COUNT}.json"

# First call: ask. Subsequent calls: allow
if [ "\$COUNT" -eq 1 ]; then
  echo '{"decision": "ask", "reason": "First invocation - asking"}'
else
  echo '{"decision": "allow", "note": "Subsequent invocation"}'
fi
exit 0
HOOK
  chmod +x "$TEST_TEMP_DIR/counting_ask_hook.sh"

  # First invocation - should ask
  echo '{"call": 1}' | "$TEST_TEMP_DIR/counting_ask_hook.sh" > "$TEST_TEMP_DIR/response1.json"

  decision1=$(jq -r '.decision' "$TEST_TEMP_DIR/response1.json")
  assert_equal "$decision1" "ask"

  # Simulate second invocation (as if user approved)
  echo '{"call": 2, "user_approved": true}' | "$TEST_TEMP_DIR/counting_ask_hook.sh" > "$TEST_TEMP_DIR/response2.json"

  decision2=$(jq -r '.decision' "$TEST_TEMP_DIR/response2.json")
  assert_equal "$decision2" "allow"

  # Verify both stdin captures exist
  assert [ -f "$TEST_TEMP_DIR/stdin_captures/invocation_1.json" ]
  assert [ -f "$TEST_TEMP_DIR/stdin_captures/invocation_2.json" ]

  # Check what was passed on second invocation
  run jq -r '.user_approved' "$TEST_TEMP_DIR/stdin_captures/invocation_2.json"
  # Note: This is what WE passed. Real test is: what does Claude pass?
  assert_equal "$output" "true"
}
