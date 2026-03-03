# ADR-0001: Go as Implementation Language

## Status

Accepted

## Context

hooks-dispatch needs to be:
- Cross-platform (Linux, macOS, Windows)
- Distributed as a single binary
- Fast to start (invoked per hook event)
- Easy to install without runtime dependencies

We considered several languages:
- **Go**: Cross-compilation, single binary, fast startup
- **Rust**: Same benefits as Go, steeper learning curve
- **Crystal**: Ruby-like syntax, less mature cross-compilation
- **Bash**: Universal but limited for complex logic
- **Python**: Requires runtime, slow startup

## Decision

Use **Go** as the implementation language.

## Rationale

### Cross-Platform Single Binary
Go compiles to standalone binaries for all major platforms:
```bash
GOOS=linux GOARCH=amd64 go build -o hooks-dispatch-linux
GOOS=darwin GOARCH=arm64 go build -o hooks-dispatch-macos
GOOS=windows GOARCH=amd64 go build -o hooks-dispatch.exe
```

No runtime dependencies. Users download and run.

### Fast Startup
Go binaries start in ~20-50ms. Critical for hook dispatch where latency matters:
- Claude Code invokes hooks synchronously
- Slow hooks block the agent
- Per-event invocation means startup time accumulates

Comparison (hello world):
| Language | Startup |
|----------|---------|
| Go | ~20ms |
| Rust | ~15ms |
| Python | ~100ms |
| Node.js | ~150ms |
| Ruby | ~200ms |

### Ecosystem

Go has mature libraries for our needs:
- `os/exec`: Process execution
- `encoding/json`: JSON parsing
- `path/filepath`: Cross-platform paths
- `cobra`: CLI framework
- `fsnotify`: File watching (future daemon mode)

### Team Familiarity

Go is widely known in the DevTools/infrastructure space. Contributors can onboard quickly.

### Considered Alternatives

**Rust**: Slightly faster startup, better memory safety. Rejected due to:
- Steeper learning curve
- Slower compilation
- Smaller contributor pool for this type of tool

**Crystal**: Ruby-like syntax, compiles to binary. Rejected due to:
- Less mature Windows support
- Smaller ecosystem
- Cross-compilation complexity

**Bash**: Universal availability. Rejected due to:
- Limited error handling
- Complex string/JSON manipulation
- Platform inconsistencies (GNU vs BSD)

**Python**: Rich ecosystem. Rejected due to:
- Requires Python runtime
- Slow startup (~100ms+)
- Version compatibility issues

## Consequences

### Positive
- Single binary distribution simplifies installation
- Fast startup keeps hook latency low
- Cross-platform support without separate builds
- Large contributor pool familiar with Go
- Excellent tooling (go fmt, go vet, go test)

### Negative
- No runtime scripting/plugins (compiled language)
- Verbose error handling (no exceptions)
- Less expressive than Ruby/Python for text processing

### Mitigations
- Scripts provide extensibility (hooks-dispatch just dispatches)
- Standard Go error handling patterns
- Use existing libraries for JSON/text processing

## References

- [Go Cross Compilation](https://go.dev/doc/install/source#environment)
- [Lefthook](https://github.com/evilmartians/lefthook) - Similar Go tool for git hooks
- [Task](https://taskfile.dev/) - Go-based task runner
- [Original Brief](../../ORIGINAL_BRIEF.md) - Project requirements
