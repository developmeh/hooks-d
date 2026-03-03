# ADR-0002: Decision Pass-Through

## Status

Accepted

## Context

AI coding agents (Claude Code, Cursor, Copilot) support different decision types in their hook responses. For example:
- `allow` - permit the action
- `deny` - block the action
- `ask` - prompt user (Claude Code, Cursor)
- Future agents may add more

We needed to decide how hooks-dispatch handles these varying decision types.

## Decision

**hooks-dispatch only interprets `allow` and `deny` for chain control. All other decisions pass through unchanged.**

| Decision | hooks-dispatch behavior |
|----------|------------------------|
| `deny` | Stop chain, return to agent |
| `allow` | Continue chain |
| anything else | Continue chain, pass through |

## Rationale

### Unix Philosophy
Do one thing well. hooks-dispatch dispatches scripts and controls execution order. Interpreting agent-specific decisions is not our job.

### Agent Independence
Each agent evolves independently. Claude Code might add `warn`, Cursor might add `defer`. By passing through unknown decisions, we don't need updates when agents add features.

### User Freedom
Users can return whatever their target agent supports. If they want `ask` behavior and their agent supports it, they return `{"decision": "ask"}`. Not our concern.

### Simplicity
Two code paths: `deny` (stop) or not-`deny` (continue). No switch statements, no agent-specific logic, no feature flags.

## Consequences

### Positive
- No coupling to agent-specific features
- Forward compatible with new agent decisions
- Simple implementation
- Users have full control

### Negative
- Can't validate decisions against agent capabilities
- Can't provide helpful errors for typos (`"decsion": "deny"`)
- Users must know their target agent's supported decisions

### Acceptable Trade-offs
The negatives are acceptable because:
- Validation is the agent's job, not ours
- JSON schema validation can catch typos if needed
- Users writing hooks already need to know their agent

## Examples

```bash
# Works - we understand deny
echo '{"decision": "deny", "reason": "Blocked"}'

# Works - we pass through ask to the agent
echo '{"decision": "ask", "reason": "Confirm?"}'

# Works - agent-specific, we just pass it
echo '{"decision": "warn", "severity": "low"}'

# Works - we don't care what it is
echo '{"decision": "yolo"}'
```

All of the above continue the chain (except `deny`) and return to the agent.
