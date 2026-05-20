function Get-KeepAChangelogFooterLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$RepositoryState,

        [string]$PreviousReleaseReference
    )

    if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        return $null
    }

    $repositoryLinkData = Get-KeepAChangelogRepositoryLinkData -RepositoryState $RepositoryState
    $compareLink = Get-KeepAChangelogCompareLink `
        -RepositoryLinkData $repositoryLinkData `
        -BaseReference $PreviousReleaseReference `
        -TargetReference $repositoryLinkData.UnreleasedTargetReference

    return "[Unreleased]: $compareLink"
}
