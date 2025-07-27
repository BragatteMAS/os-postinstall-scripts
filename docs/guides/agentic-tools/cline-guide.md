# BMad Method Guide for Cline (VS Code)

For the complete workflow, see the [BMad Workflow Guide](../bmad-workflow-guide.md).

## Installation

When running `npx bmad-method install`, select **Cline** as your IDE. This creates:

- `.clinerules/` directory with numbered agent rule files (`.md`)
- Agents ordered by priority (bmad-master first)

## Using BMad Agents in Cline

1. **Open Cline panel** in VS Code
2. **Type `@agent-name`** in the chat (e.g., `@dev`, `@sm`, `@architect`)
3. The agent adopts that persona for the conversation
