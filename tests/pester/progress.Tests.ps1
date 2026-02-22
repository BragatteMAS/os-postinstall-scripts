#Requires -Modules Pester
# Pester v5 tests for src/platforms/windows/core/progress.psm1
# Tests Show-DryRunBanner, Get-PlatformStepCount, Show-CompletionSummary
#
# Mirrors Bash tests/test-core-progress.bats behavioral contracts:
#   - show_dry_run_banner -> Show-DryRunBanner (banner when DRY_RUN=true)
#   - count_platform_steps -> Get-PlatformStepCount (count platform-relevant files)
#   - show_completion_summary -> Show-CompletionSummary (end-of-run summary with duration)

Describe 'Progress Module' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../src/platforms/windows/core/progress.psm1" -Force
    }

    BeforeEach {
        $env:DRY_RUN = $null
        $env:FAILURE_LOG = $null
        $env:NO_COLOR = '1'
        Mock Write-Host {}
    }

    AfterEach {
        $env:DRY_RUN = $null
        $env:FAILURE_LOG = $null
        $env:NO_COLOR = $null
    }

    Context 'Show-DryRunBanner' {
        It 'Is no-op when DRY_RUN is not true' {
            $env:DRY_RUN = $null
            Show-DryRunBanner
            Should -Invoke Write-Host -Times 0 -Scope It
        }

        It 'Displays banner when DRY_RUN=true' {
            $env:DRY_RUN = 'true'
            Show-DryRunBanner
            # 3 Write-Log calls -> 3 Write-Host calls with NO_COLOR=1
            Should -Invoke Write-Host -Times 3 -Scope It
        }
    }

    Context 'Get-PlatformStepCount' {
        It 'Returns 0 for missing file' {
            $result = Get-PlatformStepCount -ProfileFile (Join-Path $TestDrive 'nonexistent.txt')
            $result | Should -Be 0
        }

        It 'Counts Windows-relevant entries' {
            # winget.txt, cargo.txt, npm.txt, ai-tools.txt are Windows-relevant
            # apt.txt, brew.txt are not
            @('winget.txt', 'apt.txt', 'cargo.txt', 'npm.txt', '# comment', '', 'ai-tools.txt', 'brew.txt') |
                Set-Content (Join-Path $TestDrive 'test-profile.txt')

            $result = Get-PlatformStepCount -ProfileFile (Join-Path $TestDrive 'test-profile.txt')
            $result | Should -Be 4
        }
    }

    Context 'Show-CompletionSummary' {
        It 'Shows success with no failures' {
            # Point FAILURE_LOG to a non-existent file (no failures)
            $env:FAILURE_LOG = (Join-Path $TestDrive 'empty-failures.log')

            Show-CompletionSummary -Profile 'test' -Platform 'Test' -StartTime (Get-Date).AddSeconds(-5)

            # Should invoke Write-Host at least 4 times:
            # empty line + banner + profile + platform + duration + empty line + success + empty line
            Should -Invoke Write-Host -Times 4 -Scope It
        }
    }
}
