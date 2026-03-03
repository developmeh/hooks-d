# Existing Hook Managers and Dispatch Systems

Research completed for hooks-dispatch project.

## Executive Summary

**No existing tool solves this problem comprehensively.** While many tools excel at specific aspects (git hooks, webhooks, filesystem watching), none combine:
- Generic hook dispatching (not git-specific)
- File-system based configuration
- Multi-agent support (Claude Code, Cursor, Copilot)
- Cross-platform portability
- Termination control and visualization

hooks-dispatch addresses a genuine gap.

---

## Existing Solutions Analyzed

### 1. Generic Hook Dispatchers

#### PluginHook (progrium/pluginhook)
- **Type**: Shell-based plugin dispatcher
- **Features**: Plugin directories, fan-out to multiple handlers, pipelined STDIN, numeric ordering prefixes
- **Limitations**: Bash-based, minimal docs, inactive project
- **Relevance**: Similar concept but simpler/less maintained

#### NetworkManager Dispatcher
- **Type**: D-Bus activated script runner
- **Features**: Alphabetical ordering, event arguments, async execution, timeouts
- **Limitations**: Linux/D-Bus specific
- **Relevance**: Proven pattern for ordered directory-based execution

### 2. Git Hook Managers

#### Lefthook (evilmartians/lefthook)
- **Language**: Go
- **Features**: YAML config, parallel execution, language agnostic
- **Limitations**: Git-specific
- **Relevance**: Good patterns but too specialized

#### pre-commit (Python)
- **Features**: Remote hook repos, large community, YAML config
- **Limitations**: Python-based, git-focused
- **Relevance**: Overengineered for our use case

#### Husky (npm)
- **Features**: 2kB footprint, zero deps, auto-install
- **Limitations**: JavaScript/npm only
- **Relevance**: Shows simplicity principle

### 3. Webhook Servers

#### Webhook (adnanh/webhook)
- **Language**: Go
- **Features**: JSON config, HTTP to shell mapping, lightweight binary
- **Limitations**: HTTP-based, not filesystem discovery
- **Relevance**: Go implementation pattern

### 4. Filesystem Watchers

#### iWatch / incron
- **Features**: inotify-based, event masks, variable substitution
- **Limitations**: Filesystem watching, not hook events
- **Relevance**: Different use case entirely

### 5. Task Runners

#### Task (taskfile.dev)
- **Language**: Go
- **Features**: YAML config, sequential/parallel, dependencies
- **Limitations**: Build-focused, not event-based
- **Relevance**: Config patterns only

---

## Gap Analysis

### Problems with Existing Solutions

| Category | Tools | Why Insufficient |
|----------|-------|------------------|
| Git-centric | Lefthook, Husky, pre-commit | Tied to git, not generic |
| Webhook servers | webhook, webhookd | Require HTTP, not filesystem |
| Filesystem watchers | iWatch, incron | Wrong paradigm (file changes vs hooks) |
| System-specific | NetworkManager | Not portable |
| Inactive | PluginHook | No termination control, abandoned |

### The Multi-Agent Gap

**No tool manages hooks across Claude Code, Cursor, and Copilot.**

Each agent has its own hook format:
- Claude Code: `~/.claude/settings.json`
- VS Code/Cursor: Extension-based
- Copilot CLI: Different config entirely

No unified abstraction layer exists.

---

## Patterns to Adopt

From the research, adopt these proven patterns:

| Pattern | Source | Application |
|---------|--------|-------------|
| Go language | Lefthook, Webhook, Task | Cross-platform single binary |
| Directory-based discovery | NetworkManager, run-parts | `hooks.d/<event>/*.sh` |
| Filename ordering | run-parts, PluginHook | `01-lint.sh`, `02-test.sh` |
| YAML configuration | Lefthook, Task | Optional manifest files |
| Event filtering | iWatch, incron | Selective execution |

---

## Unique Value Proposition

hooks-dispatch provides:

1. **Generic dispatch** - Not tied to git or specific agents
2. **Filesystem-based** - Directories and scripts, not databases
3. **Multi-agent** - Central router for all AI coding agents
4. **Termination control** - stop-on-failure, continue-on-error
5. **Ordered execution** - Filename convention (Unix philosophy)
6. **Graph visualization** - Understand event flow
7. **Single binary** - Go, easy distribution

---

## Conclusion

**Proceed with implementation.** The research validates that:
1. No complete solution exists
2. Proven patterns can be adopted (Go, directory structure, YAML)
3. Multi-agent coordination is an unserved need
4. The Unix philosophy approach (simple, composable) is correct
