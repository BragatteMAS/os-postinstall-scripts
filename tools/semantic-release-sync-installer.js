/**
 * Semantic-release plugin to sync installer package.json version
 */

const fs = require('fs');
const path = require('path');

function prepare(pluginConfig, context) {
  const { nextRelease, logger } = context;
  
  // Path to installer package.json
  const installerPackagePath = path.join(process.cwd(), 'tools', 'installer', 'package.json');
  
  if (!fs.existsSync(installerPackagePath)) {
    logger.log('Installer package.json not found, skipping sync');
    return;
  }
  
  // Read installer package.json
  const installerPackage = JSON.parse(fs.readFileSync(installerPackagePath, 'utf8'));
  
  // Update version
  installerPackage.version = nextRelease.version;
  
  // Write back
  fs.writeFileSync(installerPackagePath, JSON.stringify(installerPackage, null, 2) + '\n');
  
  logger.log(`Synced installer package.json to version ${nextRelease.version}`);
}

module.exports = { prepare };