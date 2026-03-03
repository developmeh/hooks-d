# hooks-dispatch

A Unix-style hooks daemon for AI coding agents. Provides a generic, file-system-based dispatch system that routes hook events to downstream scripts with ordering and termination control.

## Project Overview

AI coding agents (Claude Code, Cursor, Copilot, etc.) support hook systems that trigger scripts on various events. Managing hooks across multiple agents with proper ordering and control flow is cumbersome. hooks-dispatch solves this by providing a central router that:

- Listens for hook events from any agent
- Dispatches to downstream scripts based on file-system configuration
- Enforces execution order via filename conventions
- Supports termination control (stop processing on failure/signal)
- Visualizes the hook graph for debugging and documentation

## Goals

- **Simple**: Unix philosophy - do one thing well
- **Generic**: Work with multiple AI coding agents, not tied to one
- **File-system based**: Configuration lives in directories and files, not databases
- **Portable**: Single binary distribution for easy installation across platforms
- **Observable**: Display hook graphs to understand event flow

## Proposed Features

- Hook event router/listener
- File-based script discovery (e.g., `hooks.d/pre-commit/01-lint.sh`, `02-test.sh`)
- Execution ordering by filename prefix
- Termination control (continue-on-error, stop-on-failure)
- Hook graph visualization
- Configuration for multiple coding agents

## Technical Considerations

- **Language**: Go preferred for cross-platform binary distribution
- **Architecture**: Simple daemon or CLI that can be invoked by agent hook configs
- **Config format**: Directory structure with optional manifest files

## Open Questions

- Does a solution like this already exist? Research existing hook managers
- What hook events do different agents support? (Claude Code, Cursor, etc.)
- Daemon vs CLI invocation model?
- How to handle agent-specific hook configuration formats?

---

*Original brief preserved in [ORIGINAL_BRIEF.md](./ORIGINAL_BRIEF.md)*
