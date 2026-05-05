function Assert-KeepAChangelogInitialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [Parameter(Mandatory)]
        [bool]$Force
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        throw 'RepositoryUrl is required.'
    }

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        throw "File already exists at '$Path'. Use -Force to overwrite it."
    }
}
