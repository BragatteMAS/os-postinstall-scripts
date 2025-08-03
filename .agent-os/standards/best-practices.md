# Development Best Practices

## Context

Global development guidelines for Agent OS projects.

<conditional-block context-check="core-principles">
IF this Core Principles section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Core Principles already in context"
ELSE:
  READ: The following principles

## Core Principles

### Keep It Simple
- Implement code in the fewest lines possible
- Avoid over-engineering solutions
- Choose straightforward approaches over clever ones

### Optimize for Readability
- Prioritize code clarity over micro-optimizations
- Write self-documenting code with clear variable names
- Add comments for "why" not "what"

### DRY (Don't Repeat Yourself)
- Extract repeated business logic to private methods
- Extract repeated UI markup to reusable components
- Create utility functions for common operations

### File Structure
- Keep files focused on a single responsibility
- Group related functionality together
- Use consistent naming conventions
</conditional-block>

<conditional-block context-check="dependencies" task-condition="choosing-external-library">
IF current task involves choosing an external library:
  IF Dependencies section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Dependencies guidelines already in context"
  ELSE:
    READ: The following guidelines
ELSE:
  SKIP: Dependencies section not relevant to current task

## Dependencies

### Choose Libraries Wisely
When adding third-party dependencies:
- Select the most popular and actively maintained option
- Check the library's GitHub repository for:
  - Recent commits (within last 6 months)
  - Active issue resolution
  - Number of stars/downloads
  - Clear documentation
</conditional-block>

## Technology Choices

### Python Development
- **ALWAYS use UV**: Modern, fast package manager
  - Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - Virtual env: `uv venv`
  - Install deps: `uv pip install`
- **Never use pip/conda** unless absolutely necessary
- **Polars > pandas** for data manipulation
- **Type hints** sempre que possível

### JavaScript/TypeScript Runtime
- **Prefer Bun**: 3x faster than Node.js
  - Install: `curl -fsSL https://bun.sh/install | bash`
  - Run: `bun run` instead of `npm run`
  - Install: `bun install` instead of `npm install`
- **Fallback to Node.js** only if Bun incompatible
- **Package managers**: pnpm > yarn > npm

### Performance-Critical Code
- **Consider Rust** for hot paths and intensive processing
  - Use maturin for Python-Rust bindings
  - WASM for browser performance
  - Replace slow Python loops with Rust
- **Profile first**: Only optimize measured bottlenecks

### General Principles
- Choose modern, fast tools over legacy
- Prioritize Developer Experience (DX)
- Measure before optimizing
- Simplicity > Cleverness
