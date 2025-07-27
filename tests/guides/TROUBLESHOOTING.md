# 🔧 Troubleshooting Guide - Manual Testing

> **Purpose:** Help resolve common issues when running manual tests  
> **Approach:** Problem → Diagnosis → Solution  
> **Remember:** Tests should help, not hinder

## 🚨 Common Test Issues

### 1. Test Script Not Found

**Problem:**
```bash
$ ./tests/manual/smoke/minimal-base.sh
bash: ./tests/manual/smoke/minimal-base.sh: No such file or directory
```

**Solution:**
```bash
# Check current directory
pwd  # Should show project root

# If not in project root
cd /path/to/os-postinstall-scripts

# Check if test exists
ls -la tests/manual/smoke/

# If missing, you may need to checkout correct branch
git checkout v3.2.0
```

### 2. Permission Denied

**Problem:**
```bash
$ ./tests/manual/smoke/minimal-base.sh
bash: ./tests/manual/smoke/minimal-base.sh: Permission denied
```

**Solution:**
```bash
# Make test scripts executable
chmod +x tests/manual/**/*.sh

# Or run with bash explicitly
bash tests/manual/smoke/minimal-base.sh
```

### 3. Test Dependencies Missing

**Problem:**
```bash
🧪 Starting test...
❌ Error: bats not found. Some tests require bats-core.
```

**Solution:**
```bash
# Option 1: Install test dependencies
./tests/install-test-deps.sh

# Option 2: Run basic tests only
SKIP_DEPS_CHECK=1 ./tests/manual/smoke/minimal-base.sh

# Option 3: Install manually
# Ubuntu/Debian:
sudo apt-get install bats

# macOS:
brew install bats-core
```

### 4. Docker Not Available

**Problem:**
```bash
❌ Error: Docker required for integration tests
```

**Solution:**
```bash
# Option 1: Install Docker
# See https://docs.docker.com/get-docker/

# Option 2: Skip container tests
SKIP_CONTAINER_TESTS=1 ./tests/manual/integration/run-all.sh

# Option 3: Run host-only tests
./tests/manual/integration/host-only/
```

## 🔍 Test-Specific Issues

### Minimal Base Test Failures

**Problem:** Installation takes > 15 minutes
```bash
❌ Installation time: 18m 42s (FAIL - expected < 15m)
```

**Diagnosis & Solutions:**
```bash
# 1. Check internet speed
speedtest-cli  # Or visit fast.com

# 2. Use local package cache
ENABLE_APT_CACHE=1 ./setup.sh --minimal

# 3. Check for package mirrors
# Edit /etc/apt/sources.list for faster mirrors

# 4. Run during off-peak hours
# Package servers may be slow during business hours
```

### Parser Test Failures

**Problem:** Technology detection missing obvious languages
```bash
❌ Expected: Python detected
❌ Actual: No Python found
```

**Diagnosis & Solutions:**
```bash
# 1. Check test file format
cat tests/fixtures/sample-prds/python-django-project.md

# 2. Run parser with debug
DEBUG=1 ./tools/parse-context.sh test-file.md

# 3. Check keyword database
cat configs/technology-keywords.yaml | grep -i python

# 4. Test with simpler input
echo "This project uses Python and Django" | ./tools/parse-context.sh -
```

### Platform-Specific Failures

**Problem:** Test passes on Linux but fails on macOS
```bash
# Linux: ✅ PASS
# macOS: ❌ FAIL - command not found
```

**Solutions:**
```bash
# 1. Check for platform-specific tests
./tests/manual/integration/platform/macos/

# 2. Verify prerequisites
# macOS needs Homebrew
brew --version || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Use platform detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific test
else
    # Linux specific test
fi
```

## 📊 Performance Issues

### Tests Running Slowly

**Problem:** Full test suite takes > 2 hours
```bash
⏱️ Total time: 2h 15m (WARNING: expected ~90m)
```

**Solutions:**
```bash
# 1. Run tests in parallel
./tests/manual/run-parallel.sh

# 2. Skip non-critical tests
QUICK_MODE=1 ./tests/manual/full-validation.sh

# 3. Use test cache
CACHE_TEST_RESULTS=1 ./tests/manual/integration/run-all.sh

# 4. Profile slow tests
TIME_EACH_TEST=1 ./tests/manual/full-validation.sh
```

## 🐛 Debugging Failed Tests

### Enable Debug Mode

```bash
# Maximum verbosity
DEBUG=1 VERBOSE=1 ./tests/manual/smoke/minimal-base.sh

# Trace execution
set -x
./tests/manual/smoke/minimal-base.sh
set +x

# Log to file
./tests/manual/smoke/minimal-base.sh 2>&1 | tee test-debug.log
```

### Interactive Debugging

```bash
# Add breakpoint to test script
# Edit test file and add:
read -p "Press enter to continue..."  # Pause here

# Or use bash debugger
bash -x ./tests/manual/smoke/minimal-base.sh
```

### Common Debug Points

```bash
# Check environment
env | grep -E '(TEST_|DEBUG|VERBOSE)'

# Verify working directory
pwd; ls -la

# Check script source
head -n 20 ./tests/manual/smoke/minimal-base.sh

# Trace function calls
PS4='+ ${FUNCNAME[0]}:${LINENO}: ' bash -x ./test.sh
```

## 🔄 Recovery Procedures

### After Failed Test

```bash
# 1. Clean up test artifacts
./tests/manual/cleanup.sh

# 2. Reset test environment
./tests/manual/reset-env.sh

# 3. Verify system state
./tests/manual/system-check.sh

# 4. Re-run failed test only
./tests/manual/rerun-failed.sh
```

### Partial Installation Recovery

```bash
# If installation was interrupted
./setup.sh --resume

# If system is in unknown state
./setup.sh --verify-only

# Force clean reinstall (careful!)
./setup.sh --clean --minimal
```

## 📱 Getting Help

### Self-Help Resources

1. **Check test output carefully** - Tests explain what they're doing
2. **Read the source** - Test scripts are well-commented
3. **Check guides** - `tests/guides/` has detailed documentation
4. **Review examples** - `tests/fixtures/` has working examples

### Community Help

```bash
# Generate debug report
./tests/manual/generate-debug-report.sh > debug-report.txt

# Include in issue:
- OS and version
- Test command run
- Error message
- Debug report
- What you expected
- What actually happened
```

## 💡 Prevention Tips

### Before Running Tests

1. **Check requirements**
   ```bash
   ./tests/check-prerequisites.sh
   ```

2. **Update to latest**
   ```bash
   git pull origin main
   ```

3. **Clean environment**
   ```bash
   ./tests/manual/cleanup.sh
   ```

4. **Read test description**
   ```bash
   head -n 20 ./tests/manual/[test-name].sh
   ```

### Best Practices

- Run tests from project root
- Start with smoke tests
- Read output carefully
- Save test results
- Document any issues
- Don't force things

## 🎯 Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| "Command not found" | Check PATH or install tool |
| "Permission denied" | Run with sudo or check ownership |
| "No such file" | Check working directory |
| "Connection refused" | Check network/firewall |
| "Timeout" | Increase timeout or check internet |
| "Already exists" | Clean up or use --force |
| "Not enough space" | Free up disk space |
| "Invalid option" | Check script version |

---

> **Remember:** Tests are here to help, not to frustrate.  
> **Can't resolve it?** Skip the test and note it in your results.  
> **Philosophy:** Pragmatism over perfection - ship working software.