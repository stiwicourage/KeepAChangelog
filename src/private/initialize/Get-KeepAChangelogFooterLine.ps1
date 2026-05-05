function Get-KeepAChangelogFooterLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [string]$PreviousReleaseReference
    )

    if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        return $null
    }

    return "[Unreleased]: $RepositoryUrl/compare/$PreviousReleaseReference...HEAD"
}
