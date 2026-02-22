#Requires -Modules Pester
# Pester v5 tests for src/platforms/windows/core/errors.psm1
# Tests failure tracking lifecycle: add, count, clear, exit code, summary
#
# Mirrors Bash tests/test-core-errors.bats behavioral contracts:
#   - record_failure -> Add-FailedItem
#   - get_failure_count -> Get-FailureCount
#   - clear_failures -> Clear-Failures
#   - compute_exit_code -> Get-ExitCode (0=success, 1=partial)
#   - show_failure_summary -> Show-FailureSummary

Describe 'Failure Tracking' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../src/platforms/windows/core/errors.psm1" -Force
    }

    BeforeEach {
        Clear-Failures
        Mock Write-Host {}
        $env:FAILURE_LOG = $null
        $env:NO_COLOR = '1'
    }

    AfterEach {
        $env:FAILURE_LOG = $null
        $env:NO_COLOR = $null
    }

    Context 'Add-FailedItem and Get-FailureCount' {
        It 'Add-FailedItem increments failure count' {
            Add-FailedItem -Item 'pkg-a'
            Get-FailureCount | Should -Be 1
        }

        It 'Multiple failures increment correctly' {
            Add-FailedItem -Item 'pkg-a'
            Add-FailedItem -Item 'pkg-b'
            Add-FailedItem -Item 'pkg-c'
            Get-FailureCount | Should -Be 3
        }
    }

    Context 'Clear-Failures' {
        It 'Clear-Failures resets count to zero' {
            Add-FailedItem -Item 'pkg-a'
            Add-FailedItem -Item 'pkg-b'
            Clear-Failures
            Get-FailureCount | Should -Be 0
        }
    }

    Context 'Get-ExitCode semantic codes' {
        It 'Get-ExitCode returns 0 when no failures' {
            Get-ExitCode | Should -Be 0
        }

        It 'Get-ExitCode returns 1 when failures exist' {
            Add-FailedItem -Item 'pkg-a'
            Get-ExitCode | Should -Be 1
        }
    }

    Context 'Show-FailureSummary' {
        It 'Show-FailureSummary shows success when no failures' {
            { Show-FailureSummary } | Should -Not -Throw
        }
    }
}
