#!/usr/bin/env bats
# tests/test-contracts.bats -- Validation tests for Bash/PS API parity contract

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

setup() {
    CONTRACT_FILE="${BATS_TEST_DIRNAME}/contracts/api-parity.txt"
    SRC_DIR="${BATS_TEST_DIRNAME}/../src"
}

@test "api-parity.txt exists and is non-empty" {
    [ -f "$CONTRACT_FILE" ]
    [ -s "$CONTRACT_FILE" ]
}

@test "api-parity.txt is well-formed (5 pipe-separated columns per data line)" {
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        # Skip comments and empty lines
        [[ -z "$line" || "$line" == \#* ]] && continue
        # Count pipe characters -- expect exactly 4 (giving 5 columns)
        local pipe_count
        pipe_count=$(echo "$line" | tr -cd '|' | wc -c | tr -d ' ')
        if [[ "$pipe_count" -ne 4 ]]; then
            fail "Malformed line $line_num: expected 4 pipes (5 columns), got $pipe_count pipes: $line"
        fi
    done < "$CONTRACT_FILE"
}

@test "all Bash exported functions from paired modules appear in contract" {
    # Key exported functions that MUST appear in the contract.
    # Internal/alias functions (starting with _, and aliases like log, log_success, etc.) are excluded.
    local -a expected=(
        "log_ok|logging.sh"
        "log_error|logging.sh"
        "log_warn|logging.sh"
        "log_info|logging.sh"
        "log_debug|logging.sh"
        "log_banner|logging.sh"
        "record_failure|errors.sh"
        "show_failure_summary|errors.sh"
        "get_failure_count|errors.sh"
        "clear_failures|errors.sh"
        "compute_exit_code|errors.sh"
        "load_packages|packages.sh"
        "is_installed|idempotent.sh"
        "show_dry_run_banner|progress.sh"
        "count_platform_steps|progress.sh"
        "show_completion_summary|progress.sh"
    )

    local missing=0
    for entry in "${expected[@]}"; do
        local func_name="${entry%%|*}"
        local module="${entry##*|}"
        if ! grep -q "$func_name" "$CONTRACT_FILE"; then
            echo "MISSING from contract: $func_name (from $module)"
            missing=$((missing + 1))
        fi
        # Cross-reference: verify function is actually exported in source file
        local src_file="${SRC_DIR}/core/${module}"
        if [[ -f "$src_file" ]]; then
            if ! grep -q "export -f.*${func_name}" "$src_file"; then
                echo "NOT EXPORTED in source: $func_name (in $src_file)"
                missing=$((missing + 1))
            fi
        fi
    done

    [[ "$missing" -eq 0 ]] || fail "$missing function(s) missing from contract or source exports"
}

@test "all PS exported functions from paired modules appear in contract" {
    # Expected PS functions from paired modules.
    # Validated against the contract's own entries (not by running pwsh).
    # PS side is informational -- this is a Bash test suite.
    local -a expected=(
        "Write-Log|logging.psm1"
        "Add-FailedItem|errors.psm1"
        "Show-FailureSummary|errors.psm1"
        "Get-FailureCount|errors.psm1"
        "Clear-Failures|errors.psm1"
        "Get-ExitCode|errors.psm1"
        "Read-PackageFile|packages.psm1"
        "Test-WinGetInstalled|idempotent.psm1"
        "Show-DryRunBanner|progress.psm1"
        "Get-PlatformStepCount|progress.psm1"
        "Show-CompletionSummary|progress.psm1"
    )

    local missing=0
    for entry in "${expected[@]}"; do
        local func_name="${entry%%|*}"
        local module="${entry##*|}"
        if ! grep -q "$func_name" "$CONTRACT_FILE"; then
            echo "MISSING from contract: $func_name (from $module)"
            missing=$((missing + 1))
        fi
    done

    [[ "$missing" -eq 0 ]] || fail "$missing PS function(s) missing from contract"
}
