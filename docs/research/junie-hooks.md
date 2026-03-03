# JetBrains Junie Hook System

Research completed for hooks-dispatch project.

## Overview

**Junie does not have a traditional hooks system.** Unlike Claude Code, Cursor, and Copilot which use event-based hooks, Junie relies on:

- MCP (Model Context Protocol) for extensibility
- Action Allowlist for execution control
- Guidelines for behavioral customization

## Extensibility Model

### MCP Integration (Primary Extension Point)
```
.junie/mcp/mcp.json     # Project-level
~/.junie/mcp/           # User-level
```

MCP servers provide:
- External data sources (databases, APIs)
- Custom tools callable by Junie
- Dynamic context injection

### Action Allowlist
Controls which commands Junie can execute:
- Regex-based command patterns
- Configured via IDE: Tools > Junie > Action Allowlist
- No script-based hooks - just allow/deny rules

### Guidelines
```
.junie/guidelines.md    # Project coding standards
```

Behavioral customization, not event interception.

## Configuration Locations

| Config | Location | Purpose |
|--------|----------|---------|
| MCP servers | `.junie/mcp/mcp.json` | Tool extensions |
| Guidelines | `.junie/guidelines.md` | Coding standards |
| User MCP | `~/.junie/mcp/` | Personal tools |
| IDE settings | Tools > Junie | Allowlist, MCP, modes |

## IDE Integration

- Plugin ID: 26104
- IDEs: IntelliJ, PyCharm, WebStorm, GoLand, PhpStorm, RubyMine, RustRover, Rider
- Requires 2024.3.2+
- Modes: Code Mode (autonomous) vs Ask Mode (read-only)

## CLI

```bash
curl -fsSL https://junie.jetbrains.com/install.sh | bash
```

- Auth via `JUNIE_API_KEY` or personal LLM keys
- Headless mode for CI/CD
- GitHub Action available
- No hook system in CLI either

## Comparison with Other Agents

| Feature | Junie | Claude/Cursor/Copilot |
|---------|-------|----------------------|
| Event hooks | No | Yes |
| Pre-execution control | Allowlist only | Hook scripts |
| Extension model | MCP servers | Hooks + MCP |
| Config format | JSON + Markdown | JSON |

## Implications for hooks-dispatch

### Limited Integration Opportunity

Junie's lack of traditional hooks means hooks-dispatch cannot integrate directly. Options:

1. **Skip Junie support** - Focus on Claude Code, Cursor, Copilot
2. **MCP server approach** - Build hooks-dispatch as an MCP server that Junie can call
3. **Wrapper script** - If Junie gains hooks later, ready to integrate

### Recommendation

Document Junie as "not currently supported" but design hooks-dispatch's MCP output format to be compatible if Junie adds hooks or if we build an MCP adapter.

## Future Watch

JetBrains may add hooks as the agent ecosystem matures. Monitor:
- Junie changelog
- JetBrains plugin API updates
- Community requests
