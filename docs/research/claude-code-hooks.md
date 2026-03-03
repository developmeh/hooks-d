# Claude Code Hook System

Research completed for hooks-dispatch project.

## Hook Events Supported

Claude Code supports **17 hook events**:

### Session Events
| Event | Description |
|-------|-------------|
| `SessionStart` | Session begins or resumes |
| `SessionEnd` | Session terminates |
| `PreCompact` | Before context compaction |

### User Interaction Events
| Event | Description |
|-------|-------------|
| `UserPromptSubmit` | User submits prompt (before processing) |
| `Notification` | Claude Code sends notification |

### Tool Lifecycle Events
| Event | Description |
|-------|-------------|
| `PreToolUse` | Before tool executes (can block) |
| `PermissionRequest` | Permission dialog appears |
| `PostToolUse` | After tool succeeds |
| `PostToolUseFailure` | After tool fails |

### Agent Events
| Event | Description |
|-------|-------------|
| `SubagentStart` | Subagent spawned |
| `SubagentStop` | Subagent finished |
| `Stop` | Main agent finishes |
| `TeammateIdle` | Team member about to idle |
| `TaskCompleted` | Task marked complete |

### Other Events
| Event | Description |
|-------|-------------|
| `ConfigChange` | Configuration files change |
| `WorktreeCreate` | Creating isolated worktree |
| `WorktreeRemove` | Removing worktree |

## Configuration

### File Locations (priority order)
1. User-level: `~/.claude/settings.json`
2. Project-level: `.claude/settings.json` (shareable)
3. Local project: `.claude/settings.local.json` (gitignored)
4. Plugin level: `plugins/*/hooks/hooks.json`
5. Skill/agent frontmatter: YAML in component files
6. Managed policy: Organization-wide (admin-controlled)

### Configuration Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "regex_pattern",
        "hooks": [
          {
            "type": "command",
            "command": "script.sh",
            "timeout": 600,
            "async": false,
            "statusMessage": "Custom message"
          }
        ]
      }
    ]
  }
}
```

## Handler Types

| Type | Use Case | Input | Blocking |
|------|----------|-------|----------|
| `command` | Shell scripts | stdin JSON | Yes |
| `http` | External endpoints | POST body | Yes |
| `prompt` | LLM evaluation | Injected | Yes |
| `agent` | Multi-turn verification | Subagent | Yes |

## Context Passed to Hooks

All hooks receive JSON via stdin:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default|plan|acceptEdits|dontAsk|bypassPermissions",
  "hook_event_name": "PreToolUse"
}
```

### Event-Specific Fields
- `PreToolUse`: `tool_name`, `tool_input`, `tool_use_id`
- `PostToolUse`: `tool_name`, `tool_input`, `tool_response`
- `UserPromptSubmit`: `prompt`
- `Stop/SubagentStop`: `stop_hook_active`, `last_assistant_message`
- `Notification`: `message`, `title`, `notification_type`

### Environment Variables
- `$CLAUDE_PROJECT_DIR` - Project root
- `$CLAUDE_PLUGIN_ROOT` - Plugin directory
- `$CLAUDE_ENV_FILE` - SessionStart only: persist env vars
- `$CLAUDE_CODE_REMOTE` - "true" in remote environments

## Exit Codes & Control Flow

| Exit Code | Behavior |
|-----------|----------|
| `0` | Success - stdout parsed as JSON |
| `2` | Blocking error - stderr shown as feedback |
| Other | Non-blocking error (verbose mode only) |

### Output Format

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message for Claude",
  "decision": "block|allow",
  "reason": "Explanation",
  "hookSpecificOutput": {
    "permissionDecision": "allow|deny|ask",
    "updatedInput": {}
  }
}
```

## Matcher Patterns

| Event Type | Matcher Field | Examples |
|-----------|---------------|----------|
| Tool events | `tool_name` | `"Bash"`, `"Edit\|Write"` |
| SessionStart | session source | `"startup"`, `"resume"` |
| SessionEnd | exit reason | `"clear"`, `"logout"` |
| Notification | type | `"permission_prompt"` |
| SubagentStart/Stop | agent type | `"Bash"`, `"Explore"` |

**No matcher support:** UserPromptSubmit, Stop, TeammateIdle, TaskCompleted, WorktreeCreate/Remove

## Execution Model

- Hooks run in **parallel** (not sequential)
- Identical handlers are deduplicated
- Commands run with user's full permissions
- Default timeout: 600s (command), 30s (prompt), 60s (agent)
- Hooks snapshot at session startup (require restart to reload)

## Key Limitations

1. **Cannot hot-reload** - edits require session restart
2. **Parallel execution** - cannot rely on ordering
3. **PreToolUse** - cannot modify MCP tool inputs
4. **Async hooks** - cannot block, output delivered next turn
5. **Security** - runs with full user permissions, validate inputs

## Implications for hooks-dispatch

### What Claude Code Provides
- Rich event system with 17 lifecycle hooks
- JSON input/output protocol
- Matcher-based filtering
- Multiple handler types

### What hooks-dispatch Can Add
1. **Ordered execution** - Claude runs hooks in parallel; we provide sequential ordering
2. **Directory-based discovery** - hooks.d/ convention vs JSON config
3. **Cross-agent abstraction** - unified interface for Claude + Cursor + others
4. **Termination control** - stop-on-failure semantics
5. **Graph visualization** - see hook relationships

### Integration Approach
Configure Claude Code to invoke hooks-dispatch as its handler:

```json
{
  "hooks": {
    "PreToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "hooks-dispatch run PreToolUse"
      }]
    }]
  }
}
```

hooks-dispatch then handles discovery, ordering, and execution.
