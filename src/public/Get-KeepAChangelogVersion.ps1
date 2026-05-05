function Get-KeepAChangelogVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Get-KeepAChangelogModuleVersion
}
