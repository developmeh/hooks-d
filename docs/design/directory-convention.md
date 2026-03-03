# hooks.d Directory Convention

## Overview

hooks-dispatch uses a file-system-based configuration following Unix conventions. Scripts are organized in directories named after events, with execution order determined by filename prefixes.

## Directory Structure

```
hooks.d/
├── PreToolUse/
│   ├── 01-security-check.sh
│   ├── 02-lint-validation.sh
│   └── 99-audit-log.sh
├── PostToolUse/
│   ├── 01-notify.sh
│   └── 02-metrics.sh
├── SessionStart/
│   └── 01-init-env.sh
└── SessionEnd/
    └── 01-cleanup.sh
```

## Location Resolution

hooks-dispatch searches for `hooks.d/` in this order:

1. `$HOOKS_DISPATCH_DIR` (environment variable)
2. `.hooks.d/` (current project, hidden)
3. `hooks.d/` (current project, visible)
4. `~/.config/hooks-dispatch/hooks.d/` (user-level)

First match wins. No merging across locations.

## Event Directory Names

Directory names map to agent events. hooks-dispatch normalizes across agents:

| hooks-dispatch | Claude Code | Cursor | Copilot |
|----------------|-------------|--------|---------|
| `PreToolUse/` | PreToolUse | preToolUse | preToolUse |
| `PostToolUse/` | PostToolUse | postToolUse | postToolUse |
| `SessionStart/` | SessionStart | sessionStart | sessionStart |
| `SessionEnd/` | SessionEnd | sessionEnd | sessionEnd |

Case-insensitive matching. `pretooluse/` and `PreToolUse/` both work.

## Script Naming Convention

### Ordering Prefix

Scripts execute in lexicographic order by filename:

```
01-first.sh      # Runs first
02-second.sh     # Runs second
10-later.sh      # Runs later
99-last.sh       # Runs last
no-prefix.sh     # Runs after numbered scripts
```

**Recommended ranges:**
- `01-09`: Early validation, security checks
- `10-49`: Main processing
- `50-89`: Secondary processing
- `90-99`: Cleanup, logging, notifications

### Script Execution

hooks-dispatch keeps execution simple:

| Platform | Extension | Execution |
|----------|-----------|-----------|
| Unix | `.sh` | `sh <script>` |
| Unix | (other) | Direct execution (requires +x and shebang) |
| Windows | `.ps1` | `powershell -File <script>` |
| Windows | (other) | Direct execution |

**No special interpreter handling.** If you want Python, Ruby, etc.:

```bash
#!/bin/sh
# hooks.d/PreToolUse/01-check.sh
python3 "$(dirname "$0")/check.py" "$@"
```

Or make the script directly executable:
```bash
chmod +x hooks.d/PreToolUse/01-check.py
# Requires shebang: #!/usr/bin/env python3
```

This keeps hooks-dispatch simple and lets users wrap however they prefer.

### Ignored Files

- Files starting with `.` (hidden)
- Files starting with `_` (disabled)
- Files ending with `~` (backup)
- Files ending with `.bak`, `.tmp`, `.swp`
- Directories (not recursed into)

## Script Interface

### Input (stdin)

Scripts receive JSON on stdin with event context:

```json
{
  "event": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  },
  "session_id": "abc123",
  "cwd": "/home/user/project",
  "agent": "claude-code"
}
```

### Output (stdout)

Scripts output JSON to control behavior:

```json
{
  "continue": true,
  "decision": "allow",
  "reason": "Command is safe"
}
```

For blocking hooks (PreToolUse):
- `"decision": "allow"` - Permit the action, continue chain
- `"decision": "deny"` - Block the action, stop chain
- Any other value - Continue chain, pass through to agent

### Exit Codes

| Code | Meaning | Behavior |
|------|---------|----------|
| 0 | Success | Continue to next script |
| 1 | Error (continue) | Log error, continue |
| 2 | Error (stop) | Stop processing, report error |
| 3+ | Reserved | Treated as error (continue) |

## Manifest File (Optional)

An optional `manifest.yaml` in the event directory provides metadata:

```yaml
# hooks.d/PreToolUse/manifest.yaml
description: "Security and validation hooks"
timeout: 30  # seconds, per script
mode: stop-on-failure  # or continue-on-error
env:
  CUSTOM_VAR: "value"
```

If no manifest exists, defaults apply:
- `timeout: 60`
- `mode: stop-on-failure`

## Examples

### Minimal Setup
```
hooks.d/
└── PreToolUse/
    └── 01-block-dangerous.sh
```

### Full Setup
```
hooks.d/
├── PreToolUse/
│   ├── manifest.yaml
│   ├── 01-security.sh
│   ├── 02-lint.py
│   └── 99-log.sh
├── PostToolUse/
│   └── 01-notify.sh
├── SessionStart/
│   └── 01-init.sh
└── SessionEnd/
    └── 01-cleanup.sh
```

## Design Rationale

1. **File-system based**: No database, no daemon state. `ls` and `cat` are your debugging tools.

2. **Numeric prefixes**: Proven pattern from `/etc/rc.d/`, Debian `run-parts`, NetworkManager dispatcher.

3. **Extension-based execution**: Avoids requiring executable bit on all scripts. Cross-platform friendly.

4. **Case-insensitive events**: Reduces friction between agent naming conventions.

5. **No recursion**: Flat structure is simpler. Use multiple prefixed scripts instead of subdirectories.
