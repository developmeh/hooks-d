# Daemon vs CLI Invocation Model

Research completed for hooks-dispatch project.

## Recommendation: Hybrid Socket-Based CLI

Start with **pure CLI**, add **optional daemon** later if needed.

---

## Context

AI agent hooks fire relatively infrequently:
- Session events: once per session
- Tool events: multiple per session, but not high-frequency
- Not comparable to git hooks at GitHub scale (880ms overhead was problematic there)

Go binary startup: ~20-50ms - acceptable for this use case.

---

## Model Comparison

### Model 1: Pure CLI

```bash
hooks-dispatch run <event>
```

Each invocation: load config, dispatch scripts, exit.

| Pros | Cons |
|------|------|
| Simple deployment (single binary) | ~50ms startup per invocation |
| Portable (no systemd/launchd) | No persistent state/caching |
| Isolated (no daemon crashes) | No connection pooling |
| Easy testing | Limited observability |

### Model 2: Pure Daemon

```bash
hooks-dispatch daemon --socket /var/run/hooks.sock
hooks-dispatch --socket /var/run/hooks.sock <event>
```

| Pros | Cons |
|------|------|
| No startup overhead | Requires process supervisor |
| Persistent state/caching | OS-specific service files |
| Connection pooling | Single point of failure |
| Centralized observability | Resource overhead when idle |

### Model 3: Hybrid (Recommended)

```bash
# Default: stateless CLI
hooks-dispatch run <event>

# Optional: start daemon for performance
hooks-dispatch daemon --socket /tmp/hooks.sock

# CLI auto-connects to daemon if available
hooks-dispatch run <event>  # uses daemon if running, else standalone
```

| Pros | Cons |
|------|------|
| Works out-of-box (no daemon required) | More code (both paths) |
| Optional optimization for power users | Socket protocol design |
| Graceful degradation if daemon crashes | |
| Portable baseline | |

---

## Quantitative Comparison

| Factor | CLI Only | Daemon Only | Hybrid |
|--------|----------|-------------|--------|
| Startup latency | 50ms | ~5ms | 5ms (daemon) / 50ms (fallback) |
| Memory (idle) | 0 | 20-30MB | 0 baseline |
| Deployment | Minimal | High | Minimal |
| Single point of failure | No | Yes | No |
| Portability | Excellent | OS-dependent | Excellent |

---

## Implementation Plan

### Phase 1: Pure CLI
- Simplest implementation, ships fastest
- Benchmark against latency requirements
- If <100ms acceptable, may never need daemon

### Phase 2: Optional Daemon (if needed)
- Add `hooks-dispatch daemon` mode
- Unix domain socket + JSON protocol
- CLI tries socket first (10ms timeout), falls back to standalone

### Phase 3: Platform Helpers (optional)
- Document systemd user service setup
- Document launchd setup
- Provide example configs (not required)

---

## Technical Design

### Socket Protocol
Unix domain socket + JSON (like Docker)
- Simple, portable, debuggable
- No external dependencies

### Fallback Logic
```go
func dispatch(event Event) error {
    // Try daemon first (10ms timeout)
    if result, err := tryDaemonSocket(event); err == nil {
        return processResult(result)
    }
    // Fall back to standalone
    return executeStandalone(event)
}
```

---

## Decision

**Start with pure CLI.** The use case (AI agent hooks) doesn't require daemon-level performance. Add optional daemon mode later if telemetry shows bottlenecks.

This aligns with project philosophy:
- Simple (Unix philosophy)
- Portable (single binary)
- File-system based (no complex infrastructure)
