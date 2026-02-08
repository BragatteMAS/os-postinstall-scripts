# CLAUDE.md - Example

> **Snapshot:** 2026-02-08 | Reference configuration for Claude Code
> Customize sections marked with <!-- CUSTOMIZE --> for your workflow.

## Principles

**FAIR** | **DRY** | **SSoT** | **KISS** | **OMOP**

- Complete, replicable context
- Lightweight and performant
- Open source > paid services
- Simplicity is sophistication

---

## Tool Hierarchy

### 1. MCPs > Native Tools

<!-- CUSTOMIZE: Replace with YOUR installed MCP servers -->

| Need | USE (MCP) | AVOID (native) |
|------|-----------|----------------|
| Lib docs | `context7` | WebSearch |
| HTTP requests | `fetch` | WebFetch |
| Complex reasoning | `sequential-thinking` | - |

> Add your own MCPs here. Check available: `mcpl list` (if using mcpl)
> or review `~/.claude/settings.json` for configured MCP servers.

### 2. Modern CLI > Legacy

| USE | AVOID |
|-----|-------|
| `bat` | `cat` |
| `fd` | `find` |
| `rg` | `grep` |
| `eza` | `ls` |
| `delta` | `diff` |
| `zoxide` | `cd` |

> These require installation. The setup scripts handle this automatically.

---

## Interaction Rules

### Before ANY decision:
1. Present: **Pros** | **Cons** | **Recommendation**
2. Wait for explicit approval
3. Never execute changes without permission

### Commits:
<!-- CUSTOMIZE: Choose your commit workflow -->
- Suggest commit title and body, let user execute `git commit`

### Communication:
<!-- CUSTOMIZE: Set your preferred language -->
- Language: English
- Concise, no filler
- "Why" before "how"

### NEVER do:
- Edit files without approval
- Over-engineering
- Unsolicited features
- Unsolicited documentation
- Assume silence = approval

---

## Package Runners

<!-- CUSTOMIZE: Set your preferred package runners -->

### Execution order (preference):
1. `bunx` / `uvx` - zero-install runners
2. `pnpm` / `uv` - when bunx/uvx unavailable
3. `npx` / `pip` - last resort

### Universal standards:
- Paths: `pathlib.Path` or equivalent
- Encoding: UTF-8 explicit
- Dates: ISO (YYYY-MM-DD)

---

## Anti-patterns (always avoid)

- Unnecessary abstractions
- Optimizing without metrics
- Patterns for the sake of patterns
- Frameworks without real need
- Code a junior can't understand in 10 min

---

## Before Implementing

- [ ] Is there a library that solves this?
- [ ] Does it fit on one page?
- [ ] Can a junior understand it in 10 min?
- [ ] Are tests straightforward?
- [ ] Will maintenance be obvious?

**If 3+ answers are "no" → simplify before proceeding**
