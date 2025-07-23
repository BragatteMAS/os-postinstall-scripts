#!/usr/bin/env node
// interactive-setup.js - Interactive AI Context Setup Wizard

const readline = require('readline');
const fs = require('fs').promises;
const path = require('path');

// Colors
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (prompt) => new Promise(resolve => rl.question(prompt, resolve));

async function detectProjectInfo() {
  const detectedInfo = {
    hasGit: false,
    hasPackageJson: false,
    hasPipfile: false,
    hasGoMod: false,
    hasReadme: false,
    gitRemote: null,
    projectName: path.basename(process.cwd())
  };

  try {
    // Check for git
    await fs.access('.git');
    detectedInfo.hasGit = true;
    
    // Try to get remote URL
    try {
      const gitConfig = await fs.readFile('.git/config', 'utf8');
      const remoteMatch = gitConfig.match(/url = (.+)/);
      if (remoteMatch) detectedInfo.gitRemote = remoteMatch[1];
    } catch {}

    // Check for project files
    try {
      await fs.access('package.json');
      detectedInfo.hasPackageJson = true;
      const pkg = JSON.parse(await fs.readFile('package.json', 'utf8'));
      if (pkg.name) detectedInfo.projectName = pkg.name;
    } catch {}

    try {
      await fs.access('Pipfile');
      detectedInfo.hasPipfile = true;
    } catch {}

    try {
      await fs.access('go.mod');
      detectedInfo.hasGoMod = true;
    } catch {}

    try {
      await fs.access('README.md');
      detectedInfo.hasReadme = true;
    } catch {}

  } catch {}

  return detectedInfo;
}

// AI Config Generators
function generateClaudeConfig(answers, projectInfo) {
  return `# Claude-Specific Instructions

> 🤖 **Optimized for Claude (Anthropic)**

## Your Identity
You are Claude, helping with ${projectInfo.projectName}.

## Project Context
${answers.project}

## Tech Stack
${answers.stack}

## Current Focus
${answers.challenge}

## How to Help
${answers.aiHelp}

## Claude-Specific Guidelines
1. Use your deep reasoning for complex problems
2. Maintain context across long conversations
3. Provide detailed explanations when needed
4. Break down problems systematically

## Essential Commands
\`\`\`bash
# Add your project commands here
# npm start
# npm test
# npm run build
\`\`\`
`;
}

function generateCopilotConfig(answers, projectInfo) {
  return `# GitHub Copilot Instructions

## Project: ${projectInfo.projectName}
${answers.project}

## Code Style
- Tech Stack: ${answers.stack}
- Prefer async/await
- Include error handling
- Write tests alongside code

## Patterns
- Follow existing code structure
- Use meaningful names
- Keep functions focused

## Avoid
- Hardcoded values
- Console.log in production
- Commented-out code
`;
}

function generateCursorConfig(answers, projectInfo) {
  return `# Cursor Rules for ${projectInfo.projectName}

You are helping with: ${answers.project}

Tech Stack: ${answers.stack}

Rules:
1. Follow existing patterns
2. Write tests for new code
3. Handle errors properly
4. Keep code simple

Focus: ${answers.challenge}
`;
}

function generateOpenAIConfig(answers, projectInfo) {
  return `# OpenAI Codex Configuration

## System Context
You are GPT-4 helping with ${projectInfo.projectName}.

## Project Overview
${answers.project}

## Technical Details
- Stack: ${answers.stack}
- Focus: ${answers.challenge}
- AI Goals: ${answers.aiHelp}

## Guidelines
1. Optimize for clarity
2. Consider performance
3. Include comprehensive error handling
4. Write self-documenting code
`;
}

function generateGeminiConfig(answers, projectInfo) {
  return `# Gemini Context

## Project: ${projectInfo.projectName}
${answers.project}

## Configuration
- Technology: ${answers.stack}
- Priority: ${answers.challenge}
- AI Usage: ${answers.aiHelp}

## Gemini-Specific
- Leverage multimodal capabilities when relevant
- Use analytical strengths for optimization
- Provide code examples with explanations
`;
}

function generateGenericConfig(answers, projectInfo) {
  return `# AI Assistant Instructions

> 🤖 **Universal Configuration**

## Project Overview
${answers.project}

## Technical Context
- Stack: ${answers.stack}
- Users: ${answers.users}
- Challenge: ${answers.challenge}
- AI Role: ${answers.aiHelp}

## Guidelines
1. Follow project conventions
2. Write tests for new features
3. Update docs with code changes
4. Consider security implications
5. Optimize for maintainability

## Commands
\`\`\`bash
# Add your project-specific commands
\`\`\`
`;
}

async function main() {
  console.log(`${colors.blue}${colors.bright}🚀 AI Context Setup Wizard${colors.reset}`);
  console.log(`${colors.blue}${'='.repeat(25)}${colors.reset}\n`);

  // Detect project info
  console.log(`${colors.cyan}🔍 Detecting project information...${colors.reset}`);
  const projectInfo = await detectProjectInfo();
  
  // Show detected info
  console.log(`\n${colors.green}✅ Detected:${colors.reset}`);
  if (projectInfo.hasGit) console.log('  - Git repository');
  if (projectInfo.hasPackageJson) console.log('  - Node.js project');
  if (projectInfo.hasPipfile) console.log('  - Python project');
  if (projectInfo.hasGoMod) console.log('  - Go project');
  console.log(`  - Project name: ${projectInfo.projectName}\n`);

  // Choose setup level
  console.log(`${colors.yellow}Choose your setup level:${colors.reset}`);
  console.log('1) 🟢 Minimal (2 files, 5 questions) - Recommended for start');
  console.log('2) 🟡 Standard (5 files, structured) - For established projects');
  console.log('3) 🔴 Complete (All features) - For complex projects\n');
  
  const level = await question('Select (1-3): ');
  
  // Collect answers
  console.log(`\n${colors.cyan}📝 Let's set up your AI context:${colors.reset}\n`);
  
  const answers = {
    project: await question(`What does ${projectInfo.projectName} do? (one paragraph)\n> `),
    users: await question('\nWho uses it? (developers, companies, etc.)\n> '),
    stack: await question('\nMain tech stack? (languages, frameworks)\n> '),
    challenge: await question('\nBiggest current challenge?\n> '),
    aiHelp: await question('\nHow can AI best help? (debugging, docs, etc.)\n> ')
  };
  
  // Ask about AI assistant preference
  console.log(`\n${colors.cyan}🤖 Which AI assistant do you primarily use?${colors.reset}`);
  console.log('1) Claude (Anthropic)');
  console.log('2) GitHub Copilot');
  console.log('3) Cursor');
  console.log('4) ChatGPT/OpenAI');
  console.log('5) Gemini');
  console.log('6) Multiple/Other\n');
  
  const aiChoice = await question('Select (1-6): ');
  let aiConfigFile = 'AI_ASSISTANT.md';
  let aiConfigContent = '';
  
  switch(aiChoice) {
    case '1':
      aiConfigFile = 'CLAUDE.md';
      aiConfigContent = generateClaudeConfig(answers, projectInfo);
      break;
    case '2':
      aiConfigFile = '.github/copilot-instructions.md';
      await fs.mkdir('.github', { recursive: true });
      aiConfigContent = generateCopilotConfig(answers, projectInfo);
      break;
    case '3':
      aiConfigFile = '../.cursorrules'; // Goes in project root
      aiConfigContent = generateCursorConfig(answers, projectInfo);
      break;
    case '4':
      aiConfigFile = 'OPENAI_CODEX.md';
      aiConfigContent = generateOpenAIConfig(answers, projectInfo);
      break;
    case '5':
      aiConfigFile = 'GEMINI_CONTEXT.md';
      aiConfigContent = generateGeminiConfig(answers, projectInfo);
      break;
    default:
      aiConfigContent = generateGenericConfig(answers, projectInfo);
  }

  // Create .ai directory
  await fs.mkdir('.ai', { recursive: true });

  // Create QUESTIONS.md with answers
  const questionsContent = `# Project Discovery Questions

## 🎯 Project Identity

### What does this project do?
${answers.project}

### Who uses it?
${answers.users}

### What's the main tech stack?
${answers.stack}

### What's the biggest current challenge?
${answers.challenge}

### How can AI best help you?
${answers.aiHelp}

---
Generated: ${new Date().toISOString()}
`;

  await fs.writeFile('.ai/1-QUESTIONS.md', questionsContent);

  // Create README based on answers
  const readmeContent = `# ${projectInfo.projectName} - AI Context

## Project Overview
${answers.project}

## Target Audience
${answers.users}

## Technology Stack
${answers.stack}

## Current Focus
Working on: ${answers.challenge}

## AI Assistance Priorities
${answers.aiHelp}

## Project Structure
\`\`\`
${projectInfo.hasPackageJson ? '- Node.js application\n' : ''}${projectInfo.hasPipfile ? '- Python application\n' : ''}${projectInfo.hasGoMod ? '- Go application\n' : ''}- See file tree for details
\`\`\`

## Quick Start
1. Review .ai/1-QUESTIONS.md for detailed context
2. Check existing README.md for setup instructions
3. Use this context to understand the project

---
Generated from project analysis on ${new Date().toLocaleDateString()}
`;

  await fs.writeFile('.ai/2-README.md', readmeContent);

  // Create AI-specific configuration
  if (aiConfigFile.startsWith('../')) {
    await fs.writeFile(aiConfigFile.substring(3), aiConfigContent);
  } else if (aiConfigFile.startsWith('.github/')) {
    await fs.writeFile(aiConfigFile, aiConfigContent);
  } else {
    await fs.writeFile(`.ai/${aiConfigFile}`, aiConfigContent);
  }
  
  // Add more files based on level
  if (level === '2' || level === '3') {
    // Add architecture template
    const archContent = `# Architecture Overview

## System Components
- [ ] Frontend
- [ ] Backend API  
- [ ] Database
- [ ] Cache layer
- [ ] Message queue

## Key Design Decisions
1. [Add your architectural decisions]

## Data Flow
\`\`\`
User → Frontend → API → Database
\`\`\`

## Deployment Architecture
- Environment: [Development/Staging/Production]
- Infrastructure: [Cloud/On-premise]
`;
    await fs.writeFile('.ai/3-ARCHITECTURE.md', archContent);

    // Add conventions
    const conventionsContent = `# Code Conventions

## Naming Conventions
- Variables: camelCase
- Functions: camelCase  
- Classes: PascalCase
- Files: kebab-case
- Constants: UPPER_SNAKE_CASE

## Code Style
- Indentation: 2 spaces
- Max line length: 80-100 chars
- Use async/await over promises

## Git Conventions
- Branch naming: feature/*, bugfix/*, hotfix/*
- Commit format: "type: description"
  - feat: new feature
  - fix: bug fix
  - docs: documentation
  - refactor: code restructuring

## Testing
- Test files: *.test.js or *.spec.js
- Minimum coverage: 80%
`;
    await fs.writeFile('.ai/4-CONVENTIONS.md', conventionsContent);
  }

  if (level === '3') {
    // Add even more files for complete setup
    await fs.writeFile('.ai/5-DEPENDENCIES.md', '# Dependencies\n\n## Production Dependencies\n\n## Development Dependencies\n\n## Why Each Dependency');
    await fs.writeFile('.ai/ERROR-PATTERNS.md', '# Common Error Patterns\n\n## Error: [Name]\n### Symptoms\n### Cause\n### Solution\n');
    await fs.writeFile('.ai/SECURITY-GUIDELINES.md', '# Security Guidelines\n\n## Authentication\n## Authorization\n## Data Protection\n## Secrets Management\n');
  }

  // Success message
  console.log(`\n${colors.green}✅ AI context created successfully!${colors.reset}`);
  console.log(`\n${colors.yellow}📁 Created files:${colors.reset}`);
  console.log('  - .ai/1-QUESTIONS.md (with your answers)');
  console.log('  - .ai/2-README.md (generated overview)');
  if (level === '2' || level === '3') {
    console.log('  - .ai/3-ARCHITECTURE.md (template)');
    console.log('  - .ai/4-CONVENTIONS.md (template)');
  }
  if (level === '3') {
    console.log('  - .ai/5-DEPENDENCIES.md (template)');
    console.log('  - .ai/ERROR-PATTERNS.md (template)');
    console.log('  - .ai/SECURITY-GUIDELINES.md (template)');
  }

  console.log(`\n${colors.cyan}🎯 Next steps:${colors.reset}`);
  console.log('1. Review the generated files in .ai/');
  console.log('2. Fill in any template sections');
  console.log('3. AI assistants can now understand your project!');
  
  if (level === '1') {
    console.log(`\n${colors.blue}💡 Want more features?${colors.reset}`);
    console.log('Run this wizard again and choose Standard or Complete setup');
  }

  rl.close();
}

main().catch(console.error);