#!/usr/bin/env node

// AI Context Template - Interactive Setup Wizard
// Node.js-based interactive setup for AI context files

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Utility function to ask questions
const ask = (question) => {
  return new Promise((resolve) => {
    rl.question(question, resolve);
  });
};

// Main setup wizard
async function setupWizard() {
  console.log('🚀 AI Context Template - Interactive Setup Wizard');
  console.log('==============================================\n');
  
  // Basic project info
  const projectName = await ask('Project name: ');
  const projectDescription = await ask('Brief description (one line): ');
  const techStack = await ask('Main technologies (comma-separated): ');
  
  // AI tool selection
  console.log('\nWhich AI tool do you primarily use?');
  console.log('1) Claude (Anthropic)');
  console.log('2) GitHub Copilot');
  console.log('3) Cursor');
  console.log('4) ChatGPT/OpenAI');
  console.log('5) Multiple/Other');
  
  const aiChoice = await ask('\nSelect (1-5): ');
  
  // Development info
  const testCommand = await ask('\nTest command (e.g., npm test): ');
  const buildCommand = await ask('Build command (e.g., npm run build): ');
  const devCommand = await ask('Dev command (e.g., npm start): ');
  
  // Create .ai directory
  const aiDir = path.join(process.cwd(), '.ai');
  if (!fs.existsSync(aiDir)) {
    fs.mkdirSync(aiDir, { recursive: true });
  }
  
  // Generate 1-QUESTIONS.md with answers
  const questionsContent = `# Project Discovery Questions

## 🎯 Project Identity

### What exactly are we building?
**Answer**: ${projectDescription}

### What problem does this solve?
**Answer**: [To be filled]

### What makes this solution unique?
**Answer**: [To be filled]

## 🛠️ Technical Approach

### Current Tech Stack
**Answer**: ${techStack}

### Why this tech stack?
**Answer**: [To be filled]

## 🚀 Project Lifecycle

### Current Status
- **Phase**: Development
- **Completion**: [X%]
- **Blockers**: [To be filled]

## Essential Commands
- **Test**: ${testCommand}
- **Build**: ${buildCommand}
- **Dev**: ${devCommand}
`;
  
  fs.writeFileSync(path.join(aiDir, '1-QUESTIONS.md'), questionsContent);
  
  // Generate 2-README.md
  const readmeContent = `# ${projectName} - AI Context

## Project Summary
${projectDescription}

## Technical Stack
${techStack}

## Current Status
In active development

## How AI Can Help
- Code generation and suggestions
- Bug fixing and debugging
- Documentation updates
- Code review and improvements

## Key Commands
- Development: \`${devCommand}\`
- Testing: \`${testCommand}\`
- Build: \`${buildCommand}\`
`;
  
  fs.writeFileSync(path.join(aiDir, '2-README.md'), readmeContent);
  
  // Generate AI-specific config
  let aiConfigPath;
  let aiConfigContent;
  
  switch (aiChoice) {
    case '1': // Claude
      aiConfigPath = path.join(aiDir, 'CLAUDE.md');
      aiConfigContent = generateClaudeConfig(projectName, projectDescription, testCommand, buildCommand, devCommand);
      break;
    case '2': // Copilot
      const githubDir = path.join(process.cwd(), '.github');
      if (!fs.existsSync(githubDir)) {
        fs.mkdirSync(githubDir, { recursive: true });
      }
      aiConfigPath = path.join(githubDir, 'copilot-instructions.md');
      aiConfigContent = generateCopilotConfig(projectName, projectDescription);
      break;
    case '3': // Cursor
      aiConfigPath = path.join(process.cwd(), '.cursorrules');
      aiConfigContent = generateCursorConfig(projectName, techStack, testCommand);
      break;
    case '4': // OpenAI
      aiConfigPath = path.join(aiDir, 'OPENAI_CODEX.md');
      aiConfigContent = generateOpenAIConfig(projectName, projectDescription, techStack);
      break;
    default: // Generic
      aiConfigPath = path.join(aiDir, 'AI_ASSISTANT.md');
      aiConfigContent = generateGenericConfig(projectName, projectDescription, testCommand, buildCommand, devCommand);
  }
  
  fs.writeFileSync(aiConfigPath, aiConfigContent);
  
  console.log('\n✅ Setup complete!\n');
  console.log('📁 Created files:');
  console.log(`   - .ai/1-QUESTIONS.md`);
  console.log(`   - .ai/2-README.md`);
  console.log(`   - ${aiConfigPath}`);
  console.log('\n📋 Next steps:');
  console.log('1. Complete the [To be filled] sections in .ai/1-QUESTIONS.md');
  console.log('2. Review and customize the AI configuration');
  console.log('3. Add more context files as your project grows');
  console.log('\n🎯 Your AI assistant is now configured for optimal performance!');
  
  rl.close();
}

// Config generators for different AI tools
function generateClaudeConfig(name, description, test, build, dev) {
  return `# Claude-Specific Instructions

## Your Identity
You are Claude, an AI assistant by Anthropic working on ${name}.

## Project Context
${description}

## Key Commands
\`\`\`bash
# Development
${dev}

# Tests (ALWAYS RUN)
${test}

# Build
${build}
\`\`\`

## Communication Guidelines
- Default to concise responses
- Expand detail when explicitly asked
- Use structured formats (lists, tables)
- Suggest alternatives when relevant

## Quality Standards
- Always run tests before completing tasks
- Consider edge cases
- Document changes
- Follow existing patterns`;
}

function generateCopilotConfig(name, description) {
  return `# GitHub Copilot Configuration

## Project Overview
${name}: ${description}

## Completion Preferences
- **Scope**: Complete entire functions
- **Safety**: Always include error handling
- **Style**: Match surrounding code patterns
- **Testing**: Generate test cases alongside implementation

## Code Patterns
### Preferred
- Modern syntax and features
- Descriptive variable names
- Comprehensive error handling
- Clear function signatures

### Avoid
- Global variables
- Hardcoded values
- Debugging logs in production
- Commented-out code`;
}

function generateCursorConfig(name, stack, test) {
  return `# Cursor AI Rules

You are an AI assistant in Cursor IDE helping with ${name}.

## Project Context
- Stack: ${stack}
- Test command: ${test}

## Cursor-Specific Rules
1. Optimize for speed - quick iterations
2. Minimal explanations unless asked
3. Follow existing patterns exactly
4. Write tests inline with features
5. Use Cursor's Apply feature effectively

## Workflow
- Read existing code first
- Make focused changes
- Test immediately
- Commit often`;
}

function generateOpenAIConfig(name, description, stack) {
  return `# OpenAI GPT Configuration

## System Context
You are GPT-4, assisting with ${name}: ${description}

## Project Details
- Technology: ${stack}
- Purpose: ${description}

## Interaction Style
- Provide options when multiple approaches exist
- Include pros/cons for significant decisions
- Generate examples to illustrate concepts
- Consider best practices and patterns

## Quality Standards
- Production-ready code
- Comprehensive error handling
- Performance considerations
- Security best practices`;
}

function generateGenericConfig(name, description, test, build, dev) {
  return `# AI Assistant Instructions

## Project Context
You are an AI assistant helping with ${name}: ${description}

## Essential Commands
\`\`\`bash
# Development
${dev}

# Tests (ALWAYS RUN)
${test}

# Build
${build}
\`\`\`

## Project Rules
1. Follow existing code patterns
2. Write tests for new features
3. Update documentation as needed
4. Consider performance and security

## Quality Standards
- Clean, readable code
- Proper error handling
- Test coverage for new features
- Documentation for complex logic`;
}

// Run the wizard
setupWizard().catch(console.error);