# Session State - hooks-dispatch

## Project
hooks-dispatch - Unix-style hook router for AI agents

## Completed Work

### Beads Issues (12 closed)
- Research: existing solutions, Claude Code hooks, Cursor hooks, Copilot hooks, Junie hooks, daemon vs CLI
- Design: directory convention, termination control, graph visualization, init command
- ADRs: Go language choice, decision pass-through

### Design Docs
- `docs/design/directory-convention.md` - hooks.d/ structure, script naming, execution
- `docs/design/termination-control.md` - exit codes, chain control, allow/deny
- `docs/design/graph-visualization.md` - CLI output formats
- `docs/design/init-command.md` - agent setup and migration
- `docs/adr/0001-go-implementation-language.md`
- `docs/adr/0002-decision-pass-through.md`

### Test Infrastructure
- Bats framework installed (`.test/bats/`)
- 9 passing tests (`make test`)
- Fixtures for Claude hook exploration

## Key Discoveries

### Claude "ask" Format
The correct format for returning "ask" decision:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "reason": "explanation"
}
```

### Hook Behavior (Confirmed)
- Hook called **once** before tool use
- Claude shows permission prompt when hook returns "ask"
- In `--print` mode, "ask" is auto-approved

### Open Question
**Does Claude re-invoke the hook after user approves?**

We haven't confirmed this yet. The expect automation struggled with Claude's TUI timing.

## To Test Manually

```bash
.test/fixtures/simple-ask-test.sh
```

1. Ask Claude to run: `echo TESTME`
2. Approve when prompted (select Yes)
3. Exit Claude (`/exit`)
4. Script shows hook invocation count

If count > 1, Claude re-invokes hooks after approval.
If count = 1, no re-invocation.

## Relevant Files

```
.test/fixtures/ask-hook.sh              # Hook returning "ask"
.test/fixtures/pretooluse-ask-hooks.json # Claude settings
.test/fixtures/simple-ask-test.sh       # Manual test wrapper
.test/fixtures/ask-flow-test.exp        # Expect automation (WIP)
.test/integration/claude_baseline.bats  # Bats tests
```

## Next Steps

1. Run manual test to confirm re-invocation behavior
2. Write bats test documenting the finding
3. Update design docs based on findings
4. Begin implementation (Phase 3)

## Commands

```bash
make install-bats   # Install bats (if needed)
make test           # Run tests
make clean          # Clean up

# Manual ask flow test
.test/fixtures/simple-ask-test.sh
```
