function Get-KeepAChangelogFooterLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [string]$RepositoryProvider,
        [string]$PreviousReleaseReference
    )

    if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        return $null
    }

    $repositoryLinkData = Get-KeepAChangelogRepositoryLinkData `
        -RepositoryUrl $RepositoryUrl `
        -RepositoryProvider $RepositoryProvider
    return "[Unreleased]: $($repositoryLinkData.UnreleasedCompareLinkPrefix)$PreviousReleaseReference...HEAD"
}
