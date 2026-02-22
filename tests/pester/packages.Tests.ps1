#Requires -Modules Pester
# Pester v5 tests for src/platforms/windows/core/packages.psm1
# Tests Read-PackageFile with fixture files: comments, blanks, whitespace, missing files
#
# Mirrors Bash tests/test-core-packages.bats behavioral contracts:
#   - load_packages -> Read-PackageFile (reads package list, skips comments)

Describe 'Read-PackageFile' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../src/platforms/windows/core/packages.psm1" -Force
    }

    It 'Reads packages from file skipping comments and blanks' {
        @('pkg-a', '# comment', '', 'pkg-b', '  pkg-c  ') |
            Set-Content (Join-Path $TestDrive 'test.txt')

        $result = Read-PackageFile -FileName (Join-Path $TestDrive 'test.txt')

        @($result).Count | Should -Be 3
        $result | Should -Contain 'pkg-a'
        $result | Should -Contain 'pkg-b'
        $result | Should -Contain 'pkg-c'
    }

    It 'Returns empty array for missing file' {
        $result = Read-PackageFile -FileName (Join-Path $TestDrive 'nonexistent.txt') -WarningAction SilentlyContinue

        @($result).Count | Should -Be 0
    }

    It 'Trims whitespace from package names' {
        @('  spaced  ', "`ttabbed`t") |
            Set-Content (Join-Path $TestDrive 'whitespace.txt')

        $result = Read-PackageFile -FileName (Join-Path $TestDrive 'whitespace.txt')

        $result | Should -Contain 'spaced'
        $result | Should -Contain 'tabbed'
    }

    It 'Handles file with only comments and blanks' {
        @('# only comment', '', '  ') |
            Set-Content (Join-Path $TestDrive 'empty.txt')

        $result = Read-PackageFile -FileName (Join-Path $TestDrive 'empty.txt')

        @($result).Count | Should -Be 0
    }
}
