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
