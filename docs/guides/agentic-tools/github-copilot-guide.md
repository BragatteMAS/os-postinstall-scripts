# BMad Method Guide for Github Copilot

For the complete workflow, see the [BMad Workflow Guide](../bmad-workflow-guide.md).

## Installation

When running `npx bmad-method install`, select **Github Copilot** as your IDE. This command will perform the following actions:

- Create the `.bmad-core/` directory with all the agent rule files.
- Create the `.vscode/` directory and add a `settings.json` file if it does not already exist, and add the basic configuration to enable GitHub Copilot's agent mode.
- Create a chatmodes file under your .github folder for each specific agent being added

## Using BMad Agents in VS Code

1. In the GitHub Copilot Chat window, select **Agent** from the chat mode dropdown list.

## VS Code Specific Features

- **Dynamic Configuration**: When you first invoke an agent (e.g., `@dev`), VS Code will automatically update `.vscode/settings.json` by adding the configuration for that chat mode.
- **Activation**: Use the `@` prefix in the GitHub Copilot Chat for instant switching between agents.
- **Collaboration**: Fully compatible with **Live Share**, allowing you, your team, and BMad agents to work together in real-time.
- **Project Context**: Agents have full access to your workspace, including open files and the selected code.
