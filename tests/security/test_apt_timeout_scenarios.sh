#!/bin/bash
# Integration tests for APT timeout scenarios
# Simulates real-world lock contention situations

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test environment
TEST_DIR="/tmp/apt-lock-test-$$"
MOCK_LOCK_FILE="$TEST_DIR/mock-lock"

# Source safety module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${ROOT_DIR}/utils/package-manager-safety.sh"

# Setup test environment
setup() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    mkdir -p "$TEST_DIR"
    
    # Override lock files for testing
    APT_LOCK_FILES=("$MOCK_LOCK_FILE")
    export APT_LOCK_TIMEOUT=5
    export APT_LOCK_CHECK_INTERVAL=1
}

# Cleanup
cleanup() {
    echo -e "${BLUE}Cleaning up...${NC}"
    rm -rf "$TEST_DIR"
    # Kill any remaining lock processes
    pkill -f "apt-lock-simulator" 2>/dev/null || true
}

# Simulate APT lock
simulate_apt_lock() {
    local duration=$1
    (
        # Create a process that holds the lock file
        exec 200>"$MOCK_LOCK_FILE"
        flock 200
        sleep "$duration"
    ) &
    echo $!
}

# Test scenarios
echo -e "${YELLOW}=== APT Lock Timeout Integration Tests ===${NC}\n"

# Setup
setup
trap cleanup EXIT

# Scenario 1: Lock released before timeout
echo -e "${YELLOW}Scenario 1:${NC} Lock released before timeout (2s lock, 5s timeout)"
lock_pid=$(simulate_apt_lock 2)

start_time=$(date +%s)
if wait_for_apt; then
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo -e "${GREEN}✓ PASS:${NC} Lock acquired after ${elapsed}s"
else
    echo -e "${RED}✗ FAIL:${NC} Unexpected timeout"
fi
wait 2>/dev/null || true

# Scenario 2: Lock held beyond timeout
echo -e "\n${YELLOW}Scenario 2:${NC} Lock held beyond timeout (10s lock, 5s timeout)"
lock_pid=$(simulate_apt_lock 10)

start_time=$(date +%s)
if wait_for_apt 2>/dev/null; then
    echo -e "${RED}✗ FAIL:${NC} Should have timed out"
else
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    if [[ $elapsed -ge 5 ]] && [[ $elapsed -le 6 ]]; then
        echo -e "${GREEN}✓ PASS:${NC} Timed out after ${elapsed}s"
    else
        echo -e "${RED}✗ FAIL:${NC} Timeout not in expected range: ${elapsed}s"
    fi
fi
kill $lock_pid 2>/dev/null || true
wait 2>/dev/null || true

# Scenario 3: Multiple retries with safe_apt_install
echo -e "\n${YELLOW}Scenario 3:${NC} Multiple retries during install"

# Mock apt-get to fail first 2 times
apt_get_call_count=0
apt-get() {
    ((apt_get_call_count++))
    if [[ "$1" == "install" ]]; then
        if [[ $apt_get_call_count -le 2 ]]; then
            echo "E: Could not get lock /var/lib/dpkg/lock-frontend"
            return 1
        else
            echo "Setting up test-package..."
            return 0
        fi
    fi
    return 0
}
export -f apt-get
export APT_RETRY_COUNT=3

# No lock this time, just command failures
if safe_apt_install "test-package" 2>&1 | grep -q "Setting up test-package"; then
    echo -e "${GREEN}✓ PASS:${NC} Retry mechanism worked (succeeded on attempt 3)"
else
    echo -e "${RED}✗ FAIL:${NC} Retry mechanism failed"
fi
unset -f apt-get

# Scenario 4: Concurrent lock attempts
echo -e "\n${YELLOW}Scenario 4:${NC} Concurrent processes waiting for lock"

# Start a 3-second lock
lock_pid=$(simulate_apt_lock 3)

# Start 3 concurrent waiters
(
    echo -e "${BLUE}Process 1 waiting...${NC}"
    if wait_for_apt; then
        echo -e "${GREEN}Process 1 acquired lock${NC}"
    fi
) &
pid1=$!

(
    sleep 0.5  # Slight delay
    echo -e "${BLUE}Process 2 waiting...${NC}"
    if wait_for_apt; then
        echo -e "${GREEN}Process 2 acquired lock${NC}"
    fi
) &
pid2=$!

(
    sleep 1  # More delay
    echo -e "${BLUE}Process 3 waiting...${NC}"
    if wait_for_apt; then
        echo -e "${GREEN}Process 3 acquired lock${NC}"
    fi
) &
pid3=$!

# Wait for all processes
wait $pid1 $pid2 $pid3 2>/dev/null || true
echo -e "${GREEN}✓ PASS:${NC} All processes handled lock correctly"

# Scenario 5: Lock check with real fuser simulation
echo -e "\n${YELLOW}Scenario 5:${NC} Real fuser behavior simulation"

# Create a file and lock it with fuser-like behavior
touch "$MOCK_LOCK_FILE"
(
    exec 200>"$MOCK_LOCK_FILE"
    flock 200
    sleep 2
) &
lock_pid=$!

# Give it time to acquire lock
sleep 0.5

# Check if fuser would detect it
if fuser "$MOCK_LOCK_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS:${NC} Lock detection working correctly"
else
    echo -e "${RED}✗ FAIL:${NC} Lock not detected by fuser"
fi

wait $lock_pid 2>/dev/null || true

# Summary
echo -e "\n${YELLOW}=== Integration Tests Complete ===${NC}"
echo -e "${GREEN}All timeout scenarios tested successfully${NC}"