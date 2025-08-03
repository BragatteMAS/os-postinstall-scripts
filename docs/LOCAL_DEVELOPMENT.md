# Local Development Guide

> **⚠️ IMPORTANT**: This guide is for LOCAL development only. NO command here triggers automatic CI/CD.

## 🎯 Philosophy

This project adopts a **100% manual CI/CD** approach to conserve resources. The `cross-env` is used ONLY to facilitate cross-platform local development.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/bragatte/os-postinstall-scripts.git
cd os-postinstall-scripts

# 2. Install local development tools
npm install

# 3. Check your environment
npm run dev:check

# 4. Run local tests
npm run dev:test
```

## 📋 Available Commands

### Environment Check
```bash
npm run dev:check
```
Checks if your local environment has the necessary tools for development.

### Local Tests

#### Test on current platform:
```bash
npm run dev:test
```

#### Simulate test for specific platform:
```bash
npm run dev:test:linux    # Simulates Linux environment
npm run dev:test:windows  # Simulates Windows environment  
npm run dev:test:macos    # Simulates macOS environment
```

> **Note**: These are local SIMULATIONS. For real tests, use the corresponding operating system.

### Linting Local
```bash
npm run dev:lint
```
Runs ShellCheck on all shell scripts in the project.

### View all commands
```bash
npm run help
```

## 🔧 Project Structure

```
os-postinstall-scripts/
├── package.json           # NPM scripts for local dev only
├── tools/
│   └── local-dev/        # Local development tools
│       ├── check-environment.js
│       ├── test-current-platform.sh
│       ├── test-platform.sh
│       └── lint-scripts.sh
├── linux/                # Scripts for Linux
├── mac/                  # Scripts for macOS
├── windows/              # Scripts for Windows
└── profiles/             # Installation profiles
```

## 🌍 Cross-Platform com cross-env

O `cross-env` permite definir variáveis de ambiente de forma consistente:

```json
{
  "scripts": {
    "dev:test:linux": "cross-env OS_TARGET=linux TEST_MODE=local ./tools/local-dev/test-platform.sh"
  }
}
```

### Why use cross-env?

1. **Unified syntax**: Works the same on Windows, Linux and macOS
2. **Agile development**: Test locally before triggering CI/CD
3. **Resource savings**: Avoids running CI/CD for simple tests

### Available environment variables:

- `TEST_MODE`: Defines test mode (always "local" for dev)
- `OS_TARGET`: Target platform for simulation (linux/windows/darwin)
- `LINT_MODE`: Linting mode (local)
- `CHECK_MODE`: Check mode (local)

## 🚫 What NOT to do

1. **DO NOT** expect these commands to trigger CI/CD
2. **DO NOT** use npm scripts in production (they are for development only)
3. **DO NOT** confuse simulation with real platform testing

## ✅ Recommended Workflow

1. **Develop locally**
   ```bash
   # Make your changes
   vim linux/install/new-script.sh
   
   # Test locally
   npm run dev:test
   npm run dev:lint
   ```

2. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new installation script"
   ```

3. **Push to repository**
   ```bash
   git push origin feature/my-feature
   ```

4. **Request manual CI/CD** (when necessary)
   - Go to GitHub Actions
   - Select the desired workflow
   - Click "Run workflow"
   - Fill in the execution reason

## 🐛 Troubleshooting

### "ShellCheck is not installed"
```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Others
# Visit: https://github.com/koalaman/shellcheck
```

### "npm: command not found"
Install Node.js: https://nodejs.org/

### "Permission denied" when running scripts
```bash
chmod +x tools/local-dev/*.sh
```

## 📚 Additional Resources

- [cross-env documentation](https://www.npmjs.com/package/cross-env)
- [Manual CI/CD Guide](.github/TESTING_GUIDELINES.md)
- [Contributing to the project](../CONTRIBUTING.md)

## 💡 Pro Tips

1. **Use .env.local** for personal settings (not committed)
2. **Run `dev:lint` before every commit**
3. **Test on multiple platforms** using VMs or containers
4. **Document** when and why you requested CI/CD

---

> **Remember**: Efficient local development saves CI/CD resources! 🌱