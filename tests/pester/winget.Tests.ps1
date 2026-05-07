#Requires -Modules Pester
# Pester v5 tests for src/platforms/windows/install/winget.ps1
#
# v5.4.5 added a failure classifier mirroring brew-cask.sh (macOS).
# Behavior testing winget would require mocking the binary, which is non-
# trivial because winget.ps1 dot-source executes the main block. As a
# pragmatic compromise this file uses fingerprint tests (source content
# match) to ensure the classifier branches are not silently removed by
# future refactors. A Windows CI runner with winget should add real
# behavior tests on top of this contract.

Describe '[v5.4.5] winget classifier contract' {
    BeforeAll {
        $script:WingetScript = "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1"
    }

    It 'winget.ps1 exists' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        Test-Path $script:WingetScript | Should -Be $true
    }

    It 'classifier branch: package not found' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        $source = Get-Content $script:WingetScript -Raw
        $source | Should -Match 'No package found matching'
        $source | Should -Match 'package not found in winget source'
        $source | Should -Match 'winget search'
    }

    It 'classifier branch: already installed' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        $source = Get-Content $script:WingetScript -Raw
        $source | Should -Match 'already installed'
        $source | Should -Match 'state file out of sync'
    }

    It 'classifier branch: hash mismatch' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        $source = Get-Content $script:WingetScript -Raw
        $source | Should -Match 'hash.*mismatch'
        $source | Should -Match 'winget source update'
    }

    It 'classifier branch: network error' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        $source = Get-Content $script:WingetScript -Raw
        $source | Should -Match 'network error'
        $source | Should -Match 're-run setup\.ps1'
    }

    It 'failure path emits hint via Write-Log -Level INFO' -Skip:(-not (Test-Path "$PSScriptRoot/../../src/platforms/windows/install/winget.ps1")) {
        $source = Get-Content $script:WingetScript -Raw
        $source | Should -Match 'Write-Log -Level INFO -Message "  -> \$hint"'
    }
}
