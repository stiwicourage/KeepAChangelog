function Get-KeepAChangelogUnreleasedSectionError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    if (Test-KeepAChangelogHasUnreleasedSection -Body $Body) {
        return $null
    }

    $nearMatch = Find-KeepAChangelogNearUnreleasedSectionHeading -Body $Body
    if ($null -ne $nearMatch) {
        return "Found an Unreleased heading, but it is formatted as ``$nearMatch``. Expected ``## [Unreleased]``."
    }

    return 'Could not find ## [Unreleased] section in CHANGELOG.md.'
}

function Find-KeepAChangelogNearUnreleasedSectionHeading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    foreach ($headingLine in Get-KeepAChangelogHeadingCandidateList -Body $Body) {
        if (Test-KeepAChangelogNearUnreleasedHeading -HeadingLine $headingLine) {
            return $headingLine
        }
    }

    return $null
}

function Get-KeepAChangelogHeadingCandidateList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    $headingLineList = [System.Collections.Generic.List[string]]::new()
    foreach ($headingMatch in [regex]::Matches($Body, '(?m)^#{1,6}\s+.+$')) {
        $headingLineList.Add($headingMatch.Value.TrimEnd())
    }

    return @($headingLineList.ToArray())
}

function Test-KeepAChangelogNearUnreleasedHeading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HeadingLine
    )

    $headingText = Get-KeepAChangelogHeadingText -HeadingLine $HeadingLine
    $normalizedHeadingText = Get-KeepAChangelogNormalizedUnreleasedHeadingText -HeadingText $headingText
    return $normalizedHeadingText -ceq 'Unreleased'
}

function Get-KeepAChangelogHeadingText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HeadingLine
    )

    return ($HeadingLine -replace '^\s*#+\s*', '').Trim()
}

function Get-KeepAChangelogNormalizedUnreleasedHeadingText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HeadingText
    )

    $normalizedHeadingText = $HeadingText.Trim()
    $wrapperPatternList = @(
        '^\[(.+)\]$',
        '^\{(.+)\}$',
        '^\((.+)\)$'
    )

    foreach ($wrapperPattern in $wrapperPatternList) {
        if ($normalizedHeadingText -match $wrapperPattern) {
            $normalizedHeadingText = $Matches[1].Trim()
            break
        }
    }

    return (Get-Culture).TextInfo.ToTitleCase($normalizedHeadingText.ToLowerInvariant())
}
