#!/usr/bin/env node

/**
 * Local Environment Checker
 * 
 * This tool checks the local development environment for compatibility
 * with the os-postinstall-scripts project. It does NOT trigger any CI/CD.
 * 
 * Usage: npm run dev:check
 * 
 * @author Bragatte, M.A.S
 */

const os = require('os');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  purple: '\x1b[35m'
};

console.log(`${colors.purple}🔍 OS Post-Install Scripts - Local Environment Check${colors.reset}`);
console.log(`${colors.yellow}⚠️  This is a LOCAL development tool only - No CI/CD will be triggered${colors.reset}\n`);

// Check current platform
const platform = os.platform();
const platformName = {
  'darwin': 'macOS',
  'linux': 'Linux',
  'win32': 'Windows'
}[platform] || platform;

console.log(`${colors.blue}Platform:${colors.reset} ${platformName}`);
console.log(`${colors.blue}Node Version:${colors.reset} ${process.version}`);
console.log(`${colors.blue}Architecture:${colors.reset} ${os.arch()}`);
console.log(`${colors.blue}Home Directory:${colors.reset} ${os.homedir()}`);

// Check for required tools based on platform
console.log(`\n${colors.purple}Checking platform-specific tools...${colors.reset}`);

const checks = {
  'darwin': {
    'brew': 'which brew',
    'git': 'which git',
    'bash': 'which bash',
    'zsh': 'which zsh'
  },
  'linux': {
    'apt/yum/dnf': 'which apt || which yum || which dnf',
    'git': 'which git',
    'bash': 'which bash',
    'curl': 'which curl',
    'wget': 'which wget'
  },
  'win32': {
    'powershell': 'where powershell',
    'git': 'where git',
    'winget': 'where winget'
  }
};

const platformChecks = checks[platform] || checks['linux'];

Object.entries(platformChecks).forEach(([tool, command]) => {
  try {
    execSync(command, { stdio: 'pipe' });
    console.log(`${colors.green}✓${colors.reset} ${tool} found`);
  } catch (error) {
    console.log(`${colors.red}✗${colors.reset} ${tool} not found`);
  }
});

// Check project structure
console.log(`\n${colors.purple}Checking project structure...${colors.reset}`);

const requiredDirs = [
  'linux',
  'mac',
  'windows',
  'profiles',
  'docs',
  '.github/workflows'
];

const projectRoot = path.join(__dirname, '..', '..');
requiredDirs.forEach(dir => {
  const fullPath = path.join(projectRoot, dir);
  if (fs.existsSync(fullPath)) {
    console.log(`${colors.green}✓${colors.reset} ${dir}/`);
  } else {
    console.log(`${colors.red}✗${colors.reset} ${dir}/ (missing)`);
  }
});

// Check for local development files
console.log(`\n${colors.purple}Checking local development setup...${colors.reset}`);

const devFiles = [
  'package.json',
  'node_modules',
  '.env.local'
];

devFiles.forEach(file => {
  const fullPath = path.join(projectRoot, file);
  if (fs.existsSync(fullPath)) {
    console.log(`${colors.green}✓${colors.reset} ${file}`);
  } else {
    if (file === '.env.local') {
      console.log(`${colors.yellow}⚠${colors.reset} ${file} (optional - copy from .env.local.example if needed)`);
    } else if (file === 'node_modules') {
      console.log(`${colors.yellow}⚠${colors.reset} ${file} (run 'npm install' to create)`);
    } else {
      console.log(`${colors.red}✗${colors.reset} ${file}`);
    }
  }
});

// Environment variables from cross-env
console.log(`\n${colors.purple}Environment Variables:${colors.reset}`);
console.log(`CHECK_MODE: ${process.env.CHECK_MODE || 'not set'}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'not set'}`);
console.log(`TEST_MODE: ${process.env.TEST_MODE || 'not set'}`);

// Summary
console.log(`\n${colors.purple}Summary:${colors.reset}`);
console.log(`Ready for local development on ${platformName}`);
console.log(`\n${colors.blue}Next steps:${colors.reset}`);
console.log(`1. Run 'npm install' if you haven't already`);
console.log(`2. Use 'npm run dev:test' to run local tests`);
console.log(`3. Use 'npm run help' to see all available commands`);
console.log(`\n${colors.yellow}Remember: All tests run locally. CI/CD must be triggered manually in GitHub Actions.${colors.reset}`);