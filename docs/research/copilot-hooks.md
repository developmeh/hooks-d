# GitHub Copilot Hook System

Research completed for hooks-dispatch project.

## Overview

GitHub Copilot has a comprehensive hooks system configured via JSON files in `.github/hooks/*.json`. Now generally available (Feb 2026) with full CLI support.

## Hook Events

| Event | Description | Can Block |
|-------|-------------|-----------|
| `sessionStart` | Session begins/resumes | No |
| `sessionEnd` | Session completes | No |
| `userPromptSubmitted` | User submits prompt | No |
| `preToolUse` | Before tool execution | **Yes** |
| `postToolUse` | After tool execution | No |
| `agentStop` | Main agent finishes | No |
| `subagentStop` | Subagent completes | No |
| `errorOccurred` | Error conditions | No |

## Configuration

### File Location
```
.github/hooks/
├── security.json
├── logging.json
└── custom.json
```

### Schema
```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [],
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/validate.sh",
        "powershell": "./scripts/validate.ps1",
        "cwd": "scripts",
        "timeoutSec": 30,
        "comment": "Security validation"
      }
    ],
    "postToolUse": []
  }
}
```

### Cross-Platform Support
Hooks can specify both `bash` and `powershell` commands for cross-platform compatibility.

## PreToolUse Decisions

The `preToolUse` hook can return decisions:
- `allow` - Permit the tool execution
- `deny` - Block the tool execution
- `ask` - Prompt for user confirmation

## Editor Support

| Editor | Hooks | MCP | Agent Skills |
|--------|-------|-----|--------------|
| VS Code | Full | GA | Experimental |
| JetBrains | Full | Preview | Preview |
| Eclipse | Preview | GA | - |
| Xcode | Preview | GA | - |
| Visual Studio | Preview | GA | - |

## Copilot CLI

Generally available (Feb 2026) with:
- Full hook support (pre/post tool)
- MCP server integration
- Plugin installation from GitHub repos
- Model selection (Claude, GPT, Gemini)
- Cross-session memory

## Additional Extensibility

### Agent Skills
- Reusable instructions in `SKILL.md`
- Define activation criteria
- Works across VS Code, CLI, and coding agent

### Custom Agents
- Markdown-defined in `.github/agents/`
- Codify team practices
- Partner agents available (Terraform, PagerDuty, etc.)

### MCP Integration
- Model Context Protocol for external tools
- Dynamic tool discovery
- GitHub Marketplace extensions

## Comparison with Claude Code

| Feature | Copilot | Claude Code |
|---------|---------|-------------|
| Events | 8 | 17 |
| Config location | `.github/hooks/` | `.claude/settings.json` |
| Can block tools | Yes (preToolUse) | Yes (PreToolUse) |
| Cross-platform | bash + powershell | bash only |
| MCP support | Yes | Yes |

## Implications for hooks-dispatch

### Integration Approach
```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [{
      "type": "command",
      "bash": "hooks-dispatch run preToolUse"
    }]
  }
}
```

### Event Mapping
Copilot events map closely to Claude Code:
- `preToolUse` → `PreToolUse`
- `postToolUse` → `PostToolUse`
- `sessionStart` → `SessionStart`

hooks-dispatch can normalize these across agents.
