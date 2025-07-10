# BMad Method Guiding Principles

The BMad Method is a natural language framework for AI-assisted software development. These principles ensure contributions maintain the method's effectiveness.

## Core Principles

### 1. Dev Agents Must Be Lean

- **Minimize dev agent dependencies**: Development agents that work in IDEs must have minimal context overhead
- **Save context for code**: Every line counts - dev agents should focus on coding, not documentation
- **Web agents can be larger**: Planning agents (PRD Writer, Architect) used in web UI can have more complex tasks and dependencies
- **Small files, loaded on demand**: Multiple small, focused files are better than large files with many branches

### 2. Natural Language First

- **Everything is markdown**: Agents, tasks, templates - all written in plain English
- **No code in core**: The framework itself contains no programming code, only natural language instructions
- **Self-contained templates**: Templates include their own generation instructions using `[[LLM: ...]]` markup

### 3. Agent and Task Design

- **Agents define roles**: Each agent is a persona with specific expertise (e.g., Frontend Developer, API Developer)
- **Tasks are procedures**: Step-by-step instructions an agent follows to complete work
- **Templates are outputs**: Structured documents with embedded instructions for generation
- **Dependencies matter**: Explicitly declare only what's needed

## Practical Guidelines

### When to Add to Core

- Universal software development needs only
- Doesn't bloat dev agent contexts
- Follows existing agent/task/template patterns

### When to Create Expansion Packs

- Domain-specific needs beyond software development
- Non-technical domains (business, wellness, education, creative)
- Specialized technical domains (games, infrastructure, mobile)
- Heavy documentation or knowledge bases
- Anything that would bloat core agents

See [Expansion Packs Guide](../docs/expansion-packs.md) for detailed examples and ideas.

### Agent Design Rules

1. **Web/Planning Agents**: Can have richer context, multiple tasks, extensive templates
2. **Dev Agents**: Minimal dependencies, focused on code generation, lean task sets
3. **All Agents**: Clear persona, specific expertise, well-defined capabilities

### Task Writing Rules

1. Write clear step-by-step procedures
2. Use markdown formatting for readability
3. Keep dev agent tasks focused and concise
4. Planning tasks can be more elaborate
5. **Prefer multiple small tasks over one large branching task**
   - Instead of one task with many conditional paths
   - Create multiple focused tasks the agent can choose from
   - This keeps context overhead minimal
6. **Reuse common tasks** - Don't create new document creation tasks
   - Use the existing `create-doc` task
   - Pass the appropriate template with embedded LLM instructions
   - This maintains consistency and reduces duplication

### Template Rules

1. Include generation instructions with `[[LLM: ...]]` markup
2. Provide clear structure for output
3. Make templates reusable across agents
4. Use standardized markup elements:
   - `{{placeholders}}` for variables to be replaced
   - `[[LLM: instructions]]` for AI-only processing (never shown to users)
   - `REPEAT` sections for repeatable content blocks
   - `^^CONDITION^^` blocks for conditional content
   - `@{examples}` for guidance examples (never output to users)
5. NEVER display template markup or LLM instructions to users
6. Focus on clean output - all processing instructions stay internal

## Remember

- The power is in natural language orchestration, not code
- Dev agents code, planning agents plan
- Keep dev agents lean for maximum coding efficiency
- Expansion packs handle specialized domains
