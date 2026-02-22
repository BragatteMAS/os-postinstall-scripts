#Requires -Modules Pester
# Pester v5 tests for src/platforms/windows/core/logging.psm1
# Tests all 6 log levels: OK, ERROR, WARN, INFO, DEBUG, BANNER (7 tests total)

Describe 'Write-Log' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../src/platforms/windows/core/logging.psm1" -Force
    }

    BeforeEach {
        $env:NO_COLOR = '1'
        $env:VERBOSE = $null
        Mock Write-Host {}
    }

    AfterEach {
        $env:NO_COLOR = $null
        $env:VERBOSE = $null
    }

    It 'Outputs [OK] tag for OK level' {
        Write-Log -Level OK -Message 'test'
        Should -Invoke Write-Host -ParameterFilter { $Object -match '\[OK\]' }
    }

    It 'Outputs [ERROR] tag for ERROR level' {
        Write-Log -Level ERROR -Message 'test'
        Should -Invoke Write-Host -ParameterFilter { $Object -match '\[ERROR\]' }
    }

    It 'Outputs [WARN] tag for WARN level' {
        Write-Log -Level WARN -Message 'test'
        Should -Invoke Write-Host -ParameterFilter { $Object -match '\[WARN\]' }
    }

    It 'Outputs [INFO] tag for INFO level' {
        Write-Log -Level INFO -Message 'test'
        Should -Invoke Write-Host -ParameterFilter { $Object -match '\[INFO\]' }
    }

    It 'Outputs === border === format for BANNER level' {
        Write-Log -Level BANNER -Message 'test'
        Should -Invoke Write-Host -ParameterFilter { $Object -match '===' }
    }

    It 'Suppresses DEBUG when VERBOSE is not true' {
        $env:VERBOSE = $null
        Write-Log -Level DEBUG -Message 'test'
        Should -Invoke Write-Host -Times 0 -Scope It
    }

    It 'Shows DEBUG when VERBOSE=true' {
        $env:VERBOSE = 'true'
        Write-Log -Level DEBUG -Message 'test'
        Should -Invoke Write-Host -Times 1 -Scope It
    }
}
