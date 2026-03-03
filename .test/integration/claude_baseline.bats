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
