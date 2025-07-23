# Security Tests

This directory contains security tests for the OS Post-Install Scripts project, specifically focusing on the safe APT lock handling implementation (ADR-005).

## Test Files

1. **test_apt_lock_safety.sh** - Comprehensive security test suite
   - Validates no force removal of locks
   - Tests package name validation
   - Checks timeout mechanisms
   - Verifies audit logging

2. **test_apt_timeout_scenarios.sh** - Integration tests for timeout scenarios
   - Lock released before timeout
   - Lock held beyond timeout
   - Multiple retry scenarios
   - Concurrent process handling

3. **test_apt_safety_simple.sh** - Simplified tests for CI/CD
   - Works on macOS/Linux without sudo
   - Basic security validations
   - Quick sanity checks

4. **run_all_security_tests.sh** - Master test runner
   - Runs all security test suites
   - Provides summary report

## Running Tests

### Quick Test (CI/CD friendly)
```bash
./tests/security/test_apt_safety_simple.sh
```

### Full Test Suite (Linux only)
```bash
./tests/security/run_all_security_tests.sh
```

### Individual Tests
```bash
./tests/security/test_apt_lock_safety.sh
./tests/security/test_apt_timeout_scenarios.sh
```

## Test Requirements

- Bash 3.2+ (simplified tests)
- Bash 4.0+ (full test suite)
- Linux environment (for integration tests)
- No sudo required for basic tests

## Security Validations

The tests ensure:
1. ✅ No `sudo rm /var/lib/dpkg/lock*` commands exist
2. ✅ All APT scripts use safe wrapper functions
3. ✅ Package names are validated against injection
4. ✅ Timeout mechanisms work correctly
5. ✅ Operations are logged for audit trail
6. ✅ Concurrent processes are handled safely

## CI/CD Integration

The simplified test (`test_apt_safety_simple.sh`) is designed to work in CI/CD environments:
- No sudo required
- Works on macOS and Linux
- Quick execution
- Clear pass/fail status

Add to your CI workflow:
```yaml
- name: Run Security Tests
  run: ./tests/security/test_apt_safety_simple.sh
```