# Cursor Hook System

Research completed for hooks-dispatch project.

## Overview

Cursor has a sophisticated hooks system introduced in version 1.7. More comprehensive than Claude Code with 13+ lifecycle events and deeper agent integration.

## Hook Events Supported

Cursor supports extensive lifecycle events:

### Session Events
- `sessionStart` - Session begins
- `sessionEnd` - Session terminates
- `preCompact` - Before context compaction

### Tool Events
- `preToolUse` - Before tool executes
- `postToolUse` - After tool succeeds
- `postToolUseFailure` - After tool fails

### Agent Events
- `subagentStart` - Subagent spawned
- `subagentStop` - Subagent finished
- `stop` - Agent stops
- `afterAgentResponse` - After agent responds
- `afterAgentThought` - After agent thinks

### Shell Events
- `beforeShellExecution` - Before shell command
- `afterShellExecution` - After shell command

### MCP Events
- `beforeMCPExecution` - Before MCP tool
- `afterMCPExecution` - After MCP tool

### File Events
- `beforeReadFile` - Before file read
- `afterFileEdit` - After file edit
- `beforeTabFileRead` - Before tab reads file
- `afterTabFileEdit` - After tab edits file

### Prompt Events
- `beforeSubmitPrompt` - Before prompt submission

## Configuration

### File Locations
| Level | Path |
|-------|------|
| Project | `.cursor/hooks.json` (checked in) |
| User | `~/.cursor/hooks.json` |
| Enterprise (macOS) | `/Library/Application Support/Cursor/hooks.json` |
| Enterprise (Linux) | `/etc/cursor/hooks.json` |

### Configuration Format

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": "./scripts/validate.sh",
        "timeout": 30,
        "matcher": "Edit|Write"
      }
    ],
    "sessionStart": [
      {
        "command": "echo 'Session started'"
      }
    ]
  }
}
```

### Input/Output Protocol

Scripts receive JSON via stdin:
```json
{
  "event": "preToolUse",
  "tool": "Edit",
  "input": { ... },
  "session_id": "abc123"
}
```

Scripts return JSON via stdout:
```json
{
  "allow": true,
  "message": "Optional feedback"
}
```

## Plugin System (v2.5+)

Cursor introduced a Plugin Marketplace in February 2026.

### Plugin Components
| Component | Purpose |
|-----------|---------|
| MCP servers | Tool integrations |
| Skills | Domain-specific prompts |
| Subagents | Parallel execution |
| Hooks | Automation scripts |
| Rules | System instructions |

### Plugin Structure
```
.cursor-plugin/
├── plugin.json          # Manifest
├── rules/               # .mdc rule files
├── skills/              # Skill definitions
├── agents/              # Subagent configs
├── hooks/               # Hook scripts
└── mcp/                 # MCP server configs
```

## Claude Code Compatibility

Cursor can load hooks from Claude Code with automatic format conversion. This is relevant for hooks-dispatch - we may be able to target both with similar configuration.

## Implications for hooks-dispatch

### Similarities with Claude Code
- JSON configuration format
- Event-based lifecycle hooks
- stdin/stdout JSON protocol
- Matcher patterns for filtering

### Differences
- More event types (13+ vs 17)
- Different file locations (`.cursor/` vs `.claude/`)
- Plugin marketplace integration
- MCP-specific events

### Integration Approach

Configure Cursor to invoke hooks-dispatch:

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [{
      "command": "hooks-dispatch run preToolUse"
    }]
  }
}
```

hooks-dispatch would normalize the event names and handle dispatch consistently across both agents.
