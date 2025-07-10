#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const args = process.argv.slice(2);

if (args.length < 1 || args.length > 2) {
  console.log('Usage: node bump-expansion-version.js <expansion-pack-id> [major|minor|patch]');
  console.log('Default: minor');
  console.log('Example: node bump-expansion-version.js bmad-creator-tools patch');
  process.exit(1);
}

const packId = args[0];
const bumpType = args[1] || 'minor'; // default to minor

if (!['major', 'minor', 'patch'].includes(bumpType)) {
  console.error('Error: Bump type must be major, minor, or patch');
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

async function updateVersion() {
  try {
    const configPath = path.join(__dirname, '..', 'expansion-packs', packId, 'config.yaml');
    
    if (!fs.existsSync(configPath)) {
      console.error(`Error: Expansion pack '${packId}' not found`);
      console.log('\nAvailable expansion packs:');
      const expansionPacksDir = path.join(__dirname, '..', 'expansion-packs');
      const entries = fs.readdirSync(expansionPacksDir, { withFileTypes: true });
      entries.forEach(entry => {
        if (entry.isDirectory() && !entry.name.startsWith('.')) {
          console.log(`  - ${entry.name}`);
        }
      });
      process.exit(1);
    }
    
    const configContent = fs.readFileSync(configPath, 'utf8');
    const config = yaml.load(configContent);
    const oldVersion = config.version || '1.0.0';
    const newVersion = bumpVersion(oldVersion, bumpType);
    
    config.version = newVersion;
    
    const updatedYaml = yaml.dump(config, { indent: 2 });
    fs.writeFileSync(configPath, updatedYaml);
    
    console.log(`✓ ${packId}: ${oldVersion} → ${newVersion}`);
    console.log(`\n✓ Successfully bumped ${packId} with ${bumpType} version bump`);
    console.log('\nNext steps:');
    console.log('1. Test the changes');
    console.log('2. Commit: git add -A && git commit -m "chore: bump ' + packId + ' version (' + bumpType + ')"');
    
  } catch (error) {
    console.error('Error updating version:', error.message);
    process.exit(1);
  }
}

updateVersion();