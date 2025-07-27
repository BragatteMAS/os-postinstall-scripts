# Configuration System Documentation

This document describes the central configuration system implemented for the OS Post-Install Scripts project.

## Overview

The configuration system provides a centralized way to manage all installation options, features, and behaviors through a single YAML file. This replaces hardcoded values throughout the scripts and enables easy customization without modifying code.

## Key Components

### 1. Configuration File (`configs/settings/settings.yaml`)
- Central YAML file containing all configurable options
- Created from `settings.yaml.default` template on first run
- Supports environment variable substitution (e.g., `${HOME}`, `${USER}`)

### 2. Configuration Loader (`scripts/utils/config-loader.sh`)
- YAML parser for Bash 4.0+
- Functions: `load_config`, `get_config`, `is_feature_enabled`, `get_config_list`
- Handles nested configuration values with dot notation
- Performs variable substitution automatically

### 3. Integration with Scripts
Scripts now use the configuration system to:
- Detect enabled/disabled features
- Get installation paths
- Configure tool versions
- Control installation behavior

## Usage Examples

### Loading Configuration
```bash
source scripts/utils/config-loader.sh
load_config  # Uses default location
# or
load_config /path/to/custom/config.yaml
```

### Getting Configuration Values
```bash
# Get a simple value
user_name=$(get_config "user.name")

# Get with default
bmad_version=$(get_config "features.bmad.version" "latest")

# Check if feature is enabled
if is_feature_enabled "mcps.context7"; then
    echo "Context7 MCP is enabled"
fi

# Get list values
for ide in $(get_config_list "features.bmad.ides"); do
    echo "IDE: $ide"
done
```

### Configuration Structure

```yaml
# User settings
user:
  name: "${USER}"
  email: "user@example.com"

# Paths
paths:
  claude_config:
    macos: "${HOME}/Library/Application Support/Claude/claude.json"
    linux: "${HOME}/.config/Claude/claude.json"
    windows: "${APPDATA}/Claude/claude.json"

# Features
features:
  mcps:
    context7:
      enabled: true
      description: "Documentation tool"
    serena:
      enabled: true
      path: "${HOME}/.local/bin/uv"
      repo: "${HOME}/Documents/GitHub/serena"
  
  bmad:
    enabled: true
    version: "4.32.0"
    ides:
      - "cursor"
      - "claude-code"

  shell:
    modules:
      ai_tools: true
      rust_tools: true
```

## Modified Scripts

### ai-tools.sh
- Now reads MCP enablement from configuration
- Configures only enabled MCPs in claude.json
- Uses configured paths for serena and UV
- Respects BMAD version and IDE settings
- Checks if ai_tools module is enabled before running

## Testing

Manual test scripts are provided in `tests/manual/`:
- `test-ai-tools-config.sh` - Tests AI tools configuration integration

## Benefits

1. **Flexibility**: Easy to customize without code changes
2. **Profiles**: Support for minimal, standard, and full installations
3. **Platform-specific**: Different settings per OS
4. **Version control**: Settings.yaml can be gitignored for personal configs
5. **Validation**: Built-in configuration validation
6. **Dry-run support**: Test configurations before applying

## Next Steps

- Modularize zshrc configuration
- Create installation profiles (minimal, standard, full)
- Implement unattended mode
- Create interactive setup wizard