# Termination Control Semantics

## Overview

hooks-dispatch provides control over how script failures affect the execution chain. Two modes are supported: **stop-on-failure** (default) and **continue-on-error**.

## Execution Model

Scripts in an event directory execute **sequentially** in lexicographic order:

```
01-first.sh → 02-second.sh → 03-third.sh → ...
```

Each script's exit determines whether execution continues.

## Chain Termination vs Errors

**Important distinction**: A script can stop the chain without being an error.

| Scenario | Chain Stops | Is Error | Example |
|----------|-------------|----------|---------|
| Script blocks action | Yes | **No** | Security check denies `rm -rf` |
| Script crashes | Yes | Yes | Script segfaults |
| Script returns error | Depends | Yes | Exit code 2 |

A blocking decision is the script doing its job correctly. An error is the script failing to run.

## Exit Code Semantics

| Exit Code | Name | Behavior |
|-----------|------|----------|
| 0 | Success | Check JSON output for decision |
| 1 | Soft error | Log warning, continue to next |
| 2 | Hard error | Stop execution, report failure |
| 3-127 | Reserved | Treated as soft error (continue) |
| 128+ | Signal | Script killed, treated as hard error |

### Exit 0: Success
Script completed successfully. **Check the JSON output for the decision:**

```bash
# Script exits 0 but blocks the action
echo '{"decision": "deny", "reason": "Dangerous command"}'
exit 0
```

This stops the chain but is NOT an error - the script worked correctly.

### Exit 1: Soft Error
Script encountered a non-critical error. hooks-dispatch logs a warning but continues execution. Use for:
- Optional checks that shouldn't block
- Metrics collection failures
- Non-essential notifications

### Exit 2: Hard Error
Script encountered a critical error (bug, crash, misconfiguration). hooks-dispatch stops execution and reports failure. Use for:
- Script failed to run properly
- Required dependency missing
- Configuration error

### Exit 128+: Signal Death
Script was killed by signal (128 + signal number). Treated as hard error:
- SIGTERM (143): Graceful stop requested
- SIGKILL (137): Forceful termination
- SIGSEGV (139): Script crashed

## Termination Modes

### stop-on-failure (Default)

Execution stops on any hard error (exit 2) or signal death.

```yaml
# hooks.d/PreToolUse/manifest.yaml
mode: stop-on-failure
```

Behavior:
```
01-check.sh (exit 0) → continue
02-validate.sh (exit 2) → STOP, report error
03-log.sh → never runs
```

Use when: Later scripts depend on earlier ones, or any failure should block the action.

### continue-on-error

Execution continues regardless of exit codes. All scripts run.

```yaml
# hooks.d/PostToolUse/manifest.yaml
mode: continue-on-error
```

Behavior:
```
01-notify.sh (exit 2) → log error, continue
02-metrics.sh (exit 0) → continue
03-audit.sh (exit 1) → log warning, continue
```

Use when: Scripts are independent, failures shouldn't affect others.

## Timeout Handling

Scripts have a configurable timeout (default: 60 seconds).

```yaml
# hooks.d/PreToolUse/manifest.yaml
timeout: 30  # seconds
```

When timeout is reached:
1. SIGTERM sent to script
2. 5 second grace period
3. SIGKILL if still running
4. Treated as hard error (exit 137)

## Return Value Propagation

hooks-dispatch returns to the calling agent:

### On Allow (all scripts pass, no blocks)
```json
{
  "success": true,
  "decision": "allow",
  "scripts_run": 3,
  "scripts_passed": 3
}
```

### On Block (script denies action - NOT an error)
```json
{
  "success": true,
  "decision": "deny",
  "reason": "Blocked by 02-security.sh: Dangerous command detected",
  "scripts_run": 2,
  "blocking_script": "02-security.sh"
}
```

Note: `success: true` because the script ran correctly. It just decided to block.

### On Error (script failed to run)
```json
{
  "success": false,
  "decision": "deny",
  "reason": "Script 02-validate.sh failed: exit code 2",
  "scripts_run": 2,
  "scripts_passed": 1,
  "failed_script": "02-validate.sh",
  "stderr": "Python traceback: ModuleNotFoundError..."
}
```

## Script Communication

Scripts can pass data to subsequent scripts via:

### 1. Environment Variables
Set in manifest, available to all scripts:
```yaml
env:
  PROJECT_ROOT: "/home/user/project"
```

### 2. Temporary Files
Scripts can write to `$HOOKS_DISPATCH_TMPDIR`:
```bash
echo "data" > "$HOOKS_DISPATCH_TMPDIR/shared-state"
```

Cleaned up after event completes.

### 3. stdout Aggregation
Each script's stdout JSON is collected. The final aggregated result:
```json
{
  "success": true,
  "decision": "allow",
  "outputs": [
    {"script": "01-check.sh", "data": {...}},
    {"script": "02-validate.sh", "data": {...}}
  ]
}
```

## Decision Handling

For PreToolUse (blocking hooks):

### Early Termination on Block
When a script returns `"decision": "deny"`, the chain **stops immediately**:

```
01-check.sh (allow) → continue
02-security.sh (deny) → STOP (blocked, not error)
03-audit.sh → never runs
```

This is efficient - no need to run remaining scripts once blocked.

### Decision Handling

hooks-dispatch understands two decisions for chain control:

| Decision | Effect |
|----------|--------|
| `deny` | Block action, stop chain |
| `allow` | Permit action, continue chain |

**Any other decision value is passed through to the agent unchanged.**

If an agent supports `"ask"`, `"warn"`, or other decisions, your hook can return them. hooks-dispatch treats anything that isn't `deny` as "continue the chain" and passes the final decision to the agent.

```bash
# This works - hooks-dispatch passes "ask" to the agent
echo '{"decision": "ask", "reason": "Dangerous command"}'
```

We don't interpret agent-specific decisions. We just dispatch.

## Error Reporting

hooks-dispatch captures and reports:

1. **Exit code**: Numeric code from script
2. **stderr**: Last 1KB of stderr output
3. **Duration**: How long script ran
4. **Signal**: If killed by signal

Example error output:
```
[hooks-dispatch] ERROR: PreToolUse/02-validate.sh
  Exit code: 2
  Duration: 1.2s
  stderr: "Blocked: rm -rf detected in command"
```

## Design Rationale

1. **Exit 2 for hard errors**: Distinguishes intentional blocks from script bugs. Exit 1 is often used for "soft" failures in shell conventions.

2. **Sequential execution**: Enables dependencies between scripts. Parallel would be faster but complicates state sharing.

3. **Deny wins**: Security-first. A passing security check can't override a failing one.

4. **Timeouts with SIGTERM→SIGKILL**: Graceful shutdown attempt before force kill. Standard Unix pattern.

5. **stderr capture**: Provides context for debugging without requiring structured logging.
