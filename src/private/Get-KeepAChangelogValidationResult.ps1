function Get-KeepAChangelogValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $errorList = [System.Collections.Generic.List[string]]::new()
    $parts = Split-KeepAChangelogText -Text $Text
    $unreleasedCompareLinkPrefix = $null
    $previousReleaseReference = $null

    if ($parts.Body -notmatch '(?ms)^##\s+\[Unreleased\]\s*\r?\n') {
        $errorList.Add('Could not find ## [Unreleased] section in CHANGELOG.md.')
    }

    $releaseHeadingLineList = @(
        [regex]::Matches($parts.Body, '(?m)^##\s+\[(?<label>[^\]]+)\].*$') |
            ForEach-Object { $_ }
    )
    $releaseVersionList = [System.Collections.Generic.List[string]]::new()

    foreach ($releaseHeadingLine in $releaseHeadingLineList) {
        $label = $releaseHeadingLine.Groups['label'].Value
        $line = $releaseHeadingLine.Value.TrimEnd()

        if ($label -eq 'Unreleased') {
            continue
        }

        if ($line -notmatch '^## \[[^\]]+\] - \d{4}-\d{2}-\d{2}$') {
            $errorList.Add("Release section '$line' must use '## [<version>] - <date>' format.")
            continue
        }

        if ($releaseVersionList.Contains($label)) {
            $errorList.Add("Release section [$label] is duplicated.")
            continue
        }

        $releaseVersionList.Add($label)
    }

    $hasReferenceFooter = -not [string]::IsNullOrWhiteSpace($parts.Footer)

    if (-not $hasReferenceFooter -and $releaseVersionList.Count -gt 0) {
        $errorList.Add('CHANGELOG.md must end with reference links once releases exist.')
    }

    $referenceLabelCountMap = @{}

    if ($hasReferenceFooter) {
        foreach ($referenceMatch in [regex]::Matches($parts.Footer, '(?m)^\[(?<label>[^\]]+)\]:')) {
            $label = $referenceMatch.Groups['label'].Value

            if (-not $referenceLabelCountMap.ContainsKey($label)) {
                $referenceLabelCountMap[$label] = 0
            }

            $referenceLabelCountMap[$label]++
        }
    }

    foreach ($label in $referenceLabelCountMap.Keys) {
        if ($referenceLabelCountMap[$label] -gt 1) {
            $errorList.Add("Reference link [$label] is duplicated.")
        }
    }

    if ($hasReferenceFooter) {
        $unreleasedCompareLinkPattern = '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/compare/)(?<from>.+?)\.\.\.HEAD\s*$'
        $unreleasedCompareLinkMatchList = [regex]::Matches($parts.Footer, $unreleasedCompareLinkPattern)

        if ($unreleasedCompareLinkMatchList.Count -eq 0) {
            $errorList.Add('Could not find an [Unreleased] compare link in CHANGELOG.md.')
        }

        if ($unreleasedCompareLinkMatchList.Count -gt 1) {
            $errorList.Add('CHANGELOG.md must contain exactly one [Unreleased] compare link.')
        }

        if ($unreleasedCompareLinkMatchList.Count -ge 1) {
            $unreleasedCompareLinkPrefix = $unreleasedCompareLinkMatchList[0].Groups['prefix'].Value
            $previousReleaseReference = $unreleasedCompareLinkMatchList[0].Groups['from'].Value
        }
    }

    return [pscustomobject]@{
        IsValid                     = ($errorList.Count -eq 0)
        Errors                      = @($errorList.ToArray())
        UnreleasedCompareLinkPrefix = $unreleasedCompareLinkPrefix
        PreviousReleaseReference    = $previousReleaseReference
        ReleaseVersions             = @($releaseVersionList.ToArray())
    }
}
