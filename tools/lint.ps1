#Requires -Version 5.1
# tools/lint.ps1 -- Run PSScriptAnalyzer on all PowerShell files
# Usage: powershell -File tools/lint.ps1
$ProjectRoot = (Resolve-Path "$PSScriptRoot/..").Path
$SettingsFile = Join-Path $ProjectRoot 'PSScriptAnalyzerSettings.psd1'
$Errors = 0
$Checked = 0

Write-Host "=== PSScriptAnalyzer ===" -ForegroundColor Cyan

$files = @()
if (Test-Path "$ProjectRoot/src/platforms/windows") {
    $files += Get-ChildItem -Path "$ProjectRoot/src/platforms/windows" -Recurse -Include '*.ps1','*.psm1'
}
if (Test-Path "$ProjectRoot/setup.ps1") {
    $files += Get-Item "$ProjectRoot/setup.ps1"
}
if (Test-Path "$ProjectRoot/tests") {
    $files += Get-ChildItem -Path "$ProjectRoot/tests" -Filter '*.ps1'
}
if (Test-Path "$ProjectRoot/examples") {
    $files += Get-ChildItem -Path "$ProjectRoot/examples" -Filter '*.ps1'
}

$invokeArgs = @{ Severity = @('Warning', 'Error') }
if (Test-Path $SettingsFile) {
    $invokeArgs['Settings'] = $SettingsFile
}

foreach ($file in $files) {
    $Checked++
    $results = Invoke-ScriptAnalyzer -Path $file.FullName @invokeArgs
    if ($results) {
        Write-Host "  ISSUES: $($file.Name)" -ForegroundColor Yellow
        $results | Format-Table -Property Line, Severity, RuleName, Message -AutoSize
        $Errors++
    } else {
        Write-Host "  OK: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Checked: $Checked file(s)"
if ($Errors -eq 0) {
    Write-Host "All files passed PSScriptAnalyzer." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$Errors file(s) had issues." -ForegroundColor Yellow
    exit 1
}
