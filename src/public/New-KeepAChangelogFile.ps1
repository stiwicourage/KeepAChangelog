function New-KeepAChangelogFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = 'CHANGELOG.md',

        [Parameter(Mandatory)]
        [string]$RepositoryUrl,

        [string]$PreviousReleaseReference,

        [string[]]$SectionHeading = @('Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security'),

        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        throw 'RepositoryUrl is required.'
    }

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        throw "File already exists at '$Path'. Use -Force to overwrite it."
    }

    $normalizedRepositoryUrl = $RepositoryUrl.TrimEnd('/')
    $hasPreviousReleaseReference = -not [string]::IsNullOrWhiteSpace($PreviousReleaseReference)
    $lineList = [System.Collections.Generic.List[string]]::new()
    $lineList.Add('# Changelog')
    $lineList.Add('')
    $lineList.Add('All notable changes to this project will be documented in this file.')
    $lineList.Add('')
    $lineList.Add('The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),')
    $lineList.Add('and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).')
    $lineList.Add('')
    $lineList.Add('## [Unreleased]')
    $lineList.Add('')

    foreach ($heading in $SectionHeading) {
        $lineList.Add("### $heading")
        $lineList.Add('')
    }

    if ($hasPreviousReleaseReference) {
        $lineList.Add("[Unreleased]: $normalizedRepositoryUrl/compare/$PreviousReleaseReference...HEAD")
    }

    $template = ($lineList -join "`n").TrimEnd() + "`n"

    if (-not $PSCmdlet.ShouldProcess($Path, 'Create Keep a Changelog template')) {
        return
    }

    Set-Content -LiteralPath $Path -Value $template -Encoding utf8

    return [pscustomobject]@{
        Path                     = $Path
        RepositoryUrl            = $normalizedRepositoryUrl
        PreviousReleaseReference = if ($hasPreviousReleaseReference) { $PreviousReleaseReference } else { $null }
    }
}
