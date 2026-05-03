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

function Get-KeepAChangelogHeadingLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SectionHeading
    )

    return @(
        foreach ($heading in $SectionHeading) {
            "### $heading"
            ''
        }
    )
}

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

function New-KeepAChangelogTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [string]$PreviousReleaseReference,
        [Parameter(Mandatory)]
        [string[]]$SectionHeading
    )

    $footerLine = Get-KeepAChangelogFooterLine -RepositoryUrl $RepositoryUrl -PreviousReleaseReference $PreviousReleaseReference
    $lineList = @(
        '# Changelog'
        ''
        'All notable changes to this project will be documented in this file.'
        ''
        'The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),'
        'and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).'
        ''
        '## [Unreleased]'
        ''
        (Get-KeepAChangelogHeadingLines -SectionHeading $SectionHeading)
        $footerLine
    ) | Where-Object { $null -ne $_ }

    return (($lineList -join "`n").TrimEnd() + "`n")
}

function Initialize-KeepAChangelogFile {
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

    Assert-KeepAChangelogInitialization -Path $Path -RepositoryUrl $RepositoryUrl -Force $Force.IsPresent
    $normalizedRepositoryUrl = $RepositoryUrl.TrimEnd('/')
    $template = New-KeepAChangelogTemplate `
        -RepositoryUrl $normalizedRepositoryUrl `
        -PreviousReleaseReference $PreviousReleaseReference `
        -SectionHeading $SectionHeading

    if (-not $PSCmdlet.ShouldProcess($Path, 'Initialize Keep a Changelog template')) {
        return
    }

    Set-Content -LiteralPath $Path -Value $template -Encoding utf8

    return [pscustomobject]@{
        Path                     = $Path
        RepositoryUrl            = $normalizedRepositoryUrl
        PreviousReleaseReference = if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) { $null } else { $PreviousReleaseReference }
    }
}
