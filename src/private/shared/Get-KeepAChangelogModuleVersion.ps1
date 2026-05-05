function Get-KeepAChangelogModuleVersion {
    [CmdletBinding()]
    param()

    return $ExecutionContext.SessionState.Module.Version.ToString()
}
