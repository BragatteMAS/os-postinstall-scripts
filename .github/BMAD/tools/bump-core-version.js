#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const args = process.argv.slice(2);
const bumpType = args[0] || 'minor'; // default to minor

if (!['major', 'minor', 'patch'].includes(bumpType)) {
  console.log('Usage: node bump-core-version.js [major|minor|patch]');
  console.log('Default: minor');
  process.exit(1);
}

function bumpVersion(currentVersion, type) {
  const [major, minor, patch] = currentVersion.split('.').map(Number);
  
  switch (type) {
    case 'major':
      return `${major + 1}.0.0`;
    case 'minor':
      return `${major}.${minor + 1}.0`;
    case 'patch':
      return `${major}.${minor}.${patch + 1}`;
    default:
      return currentVersion;
  }
}

async function bumpCoreVersion() {
  try {
    const coreConfigPath = path.join(__dirname, '..', 'bmad-core', 'core-config.yaml');
    
    const coreConfigContent = fs.readFileSync(coreConfigPath, 'utf8');
    const coreConfig = yaml.load(coreConfigContent);
    const oldVersion = coreConfig.version || '1.0.0';
    const newVersion = bumpVersion(oldVersion, bumpType);
    
    coreConfig.version = newVersion;
    
    const updatedYaml = yaml.dump(coreConfig, { indent: 2 });
    fs.writeFileSync(coreConfigPath, updatedYaml);
    
    console.log(`✓ BMad Core: ${oldVersion} → ${newVersion}`);
    console.log(`\n✓ Successfully bumped BMad Core with ${bumpType} version bump`);
    console.log('\nNext steps:');
    console.log('1. Test the changes');
    console.log('2. Commit: git add -A && git commit -m "chore: bump core version (' + bumpType + ')"');
    
  } catch (error) {
    console.error('Error updating core version:', error.message);
    process.exit(1);
  }
}

bumpCoreVersion();