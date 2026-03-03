# Init Command Design

## Overview

`hooks-dispatch init` bootstraps hooks-dispatch for a project, configuring the target agent and migrating existing hooks.

## Command Interface

```bash
# Initialize for specific agent
hooks-dispatch init --agent=claude
hooks-dispatch init --agent=cursor
hooks-dispatch init --agent=copilot

# Initialize for multiple agents
hooks-dispatch init --agent=claude,cursor

# Dry run (show what would happen)
hooks-dispatch init --agent=claude --dry-run

# Non-interactive (CI/scripts)
hooks-dispatch init --agent=claude --yes

# Skip hook migration prompts
hooks-dispatch init --agent=claude --no-migrate
```

## What Init Does

### 1. Create hooks.d/ Structure

```
hooks.d/
├── PreToolUse/
│   └── .gitkeep
├── PostToolUse/
│   └── .gitkeep
├── SessionStart/
│   └── .gitkeep
└── SessionEnd/
    └── .gitkeep
```

### 2. Configure Agent

#### Claude Code (`--agent=claude`)

Creates/updates `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "hooks-dispatch run PreToolUse"
      }]
    }],
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "hooks-dispatch run PostToolUse"
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "hooks-dispatch run SessionStart"
      }]
    }],
    "SessionEnd": [{
      "hooks": [{
        "type": "command",
        "command": "hooks-dispatch run SessionEnd"
      }]
    }]
  }
}
```

#### Cursor (`--agent=cursor`)

Creates/updates `.cursor/hooks.json`:
```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [{
      "command": "hooks-dispatch run PreToolUse"
    }],
    "postToolUse": [{
      "command": "hooks-dispatch run PostToolUse"
    }],
    "sessionStart": [{
      "command": "hooks-dispatch run SessionStart"
    }],
    "sessionEnd": [{
      "command": "hooks-dispatch run SessionEnd"
    }]
  }
}
```

#### Copilot (`--agent=copilot`)

Creates/updates `.github/hooks/hooks-dispatch.json`:
```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [{
      "type": "command",
      "bash": "hooks-dispatch run PreToolUse"
    }],
    "postToolUse": [{
      "type": "command",
      "bash": "hooks-dispatch run PostToolUse"
    }],
    "sessionStart": [{
      "type": "command",
      "bash": "hooks-dispatch run SessionStart"
    }],
    "sessionEnd": [{
      "type": "command",
      "bash": "hooks-dispatch run SessionEnd"
    }]
  }
}
```

### 3. Hoist Existing Hooks

If the agent already has hooks configured, migrate them:

```
Detected existing Claude Code hooks:
  PreToolUse: ./scripts/security-check.sh

Migrate to hooks.d/? [Y/n] y

Created: hooks.d/PreToolUse/01-security-check.sh (moved)
Updated: .claude/settings.json (hooks-dispatch now handles PreToolUse)
```

Migration logic:
1. Detect existing hook commands in agent config
2. Copy/move scripts to `hooks.d/<event>/01-<name>.sh`
3. Update agent config to point to hooks-dispatch
4. Preserve original as `.backup` if requested

## Output

### Interactive Mode

```
$ hooks-dispatch init --agent=claude

hooks-dispatch init
===================

Creating hooks.d/ structure... done
  ✓ hooks.d/PreToolUse/
  ✓ hooks.d/PostToolUse/
  ✓ hooks.d/SessionStart/
  ✓ hooks.d/SessionEnd/

Configuring Claude Code...
  Found existing hooks in .claude/settings.json:
    PreToolUse: ./my-security-check.sh

  Migrate existing hooks? [Y/n] y
  ✓ Moved ./my-security-check.sh → hooks.d/PreToolUse/01-my-security-check.sh
  ✓ Updated .claude/settings.json

Add to .gitignore? [Y/n] y
  ✓ Added hooks.d/**/*.log to .gitignore

Done! Run 'hooks-dispatch graph' to see your hook configuration.
```

### Dry Run

```
$ hooks-dispatch init --agent=claude --dry-run

Would create:
  hooks.d/PreToolUse/.gitkeep
  hooks.d/PostToolUse/.gitkeep
  hooks.d/SessionStart/.gitkeep
  hooks.d/SessionEnd/.gitkeep

Would update:
  .claude/settings.json (add hooks-dispatch handlers)

Would migrate:
  ./my-security-check.sh → hooks.d/PreToolUse/01-my-security-check.sh

No changes made (dry run).
```

## Edge Cases

### Already Initialized
```
$ hooks-dispatch init --agent=claude

hooks.d/ already exists.
Claude Code already configured for hooks-dispatch.

Nothing to do. Use --force to reconfigure.
```

### Multiple Agents
```
$ hooks-dispatch init --agent=claude,cursor

Creating hooks.d/ structure... done
Configuring Claude Code... done
Configuring Cursor... done

Both agents now use shared hooks.d/ configuration.
```

### Conflicting Hooks
```
$ hooks-dispatch init --agent=claude

Warning: .claude/settings.json has hooks not managed by hooks-dispatch.
  PreToolUse has 2 existing hooks

Options:
  [1] Migrate all to hooks.d/ (recommended)
  [2] Keep existing, add hooks-dispatch alongside
  [3] Abort

Choice [1]:
```

## Design Rationale

1. **Agent-specific**: Each agent has different config formats. Init handles the translation.

2. **Migration support**: Users have existing hooks. Don't make them start over.

3. **Dry run**: Let users preview changes before making them.

4. **Non-interactive**: Support CI/automation with `--yes`.

5. **No opinions**: Just structure, no default hooks. Users write their own.

6. **Idempotent**: Running init twice is safe.
