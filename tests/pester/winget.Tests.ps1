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

# ─────────────────────────────────────────────────────────────────────
# BEHAVIOR TEST SCAFFOLD (v5.5.0 Item 3)
# ─────────────────────────────────────────────────────────────────────
# These tests require:
#   1. Windows host with winget installed
#   2. Pester v5+
#   3. The winget.ps1 file refactored to expose Install-WinGetPackage
#      WITHOUT executing the main block on dot-source (currently
#      Banner write + module imports run at script load).
#
# Until (3) is done, leave these as `-Skip` placeholders. Windows CI
# runner can flip the gate to enable behavior coverage in addition to
# the fingerprint contracts above.
#
# How to refactor winget.ps1 for testability:
#   - Wrap main block in `if ($MyInvocation.InvocationName -ne '.')`
#   - OR: split function definitions into a .psm1 module, keep .ps1
#     as a thin runner that imports the module + calls the entry point.
#   - The .psm1 path is preferred (matches errors.psm1, packages.psm1,
#     logging.psm1 already in src/platforms/windows/core/).

Describe '[v5.5.0] winget classifier behavior (Windows runner only)' {

    BeforeAll {
        $script:CanRun = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
        if ($script:CanRun) {
            # TODO: source winget.ps1 functions without triggering main block.
            # See refactor instructions in the comment above this Describe.
        }
    }

    It 'classifies "No package found" failure with hint' -Skip:(-not $script:CanRun) {
        # PSEUDOCODE:
        #   Mock winget {
        #       $script:LASTEXITCODE = 1
        #       'No package found matching: madeup-pkg'
        #   } -Verifiable
        #   Mock Test-WinGetInstalled { $false }
        #   Mock Add-FailedItem { }
        #   $output = Install-WinGetPackage -PackageId 'madeup-pkg' 4>&1
        #   $output | Should -Match 'package not found in winget source'
        #   $output | Should -Match 'winget search madeup-pkg'
        Set-ItResult -Skipped -Because 'requires winget.ps1 refactor (see comment)'
    }

    It 'classifies "already installed" failure with reconcile hint' -Skip:(-not $script:CanRun) {
        Set-ItResult -Skipped -Because 'requires winget.ps1 refactor (see comment)'
    }

    It 'classifies network HRESULT 0x80072... failure as network error' -Skip:(-not $script:CanRun) {
        Set-ItResult -Skipped -Because 'requires winget.ps1 refactor (see comment)'
    }
}
