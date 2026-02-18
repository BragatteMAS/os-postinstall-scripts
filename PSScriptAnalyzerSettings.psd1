@{
    # Write-Host is appropriate for CLI tools (not modules consumed by other scripts)
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}
