function Get-KeepAChangelogUnreleasedCompareLinkData {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Footer,
        [switch]$HasReferenceFooter,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ErrorList
    )

    $result = [pscustomobject]@{
        UnreleasedCompareLinkPrefix = $null
        UnreleasedTargetReference   = $null
        PreviousReleaseReference    = $null
    }

    if (-not $HasReferenceFooter) {
        return $result
    }

    $patternList = @(
        '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/(?:compare|-/compare)/)(?<from>.+?)\.\.\.(?<target>HEAD)\s*$',
        '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/branchCompare\?baseVersion=)(?<from>.+?)(?:&|&amp;)targetVersion=(?<target>.+?)(?:&|&amp;)_a=commits\s*$'
    )
    $matchList = [System.Collections.Generic.List[System.Text.RegularExpressions.Match]]::new()

    foreach ($pattern in $patternList) {
        foreach ($match in [regex]::Matches($Footer, $pattern)) {
            $matchList.Add($match)
        }
    }

    if ($matchList.Count -eq 0) {
        $ErrorList.Add('Could not find an [Unreleased] compare link in CHANGELOG.md.')
        return $result
    }

    if ($matchList.Count -gt 1) {
        $ErrorList.Add('CHANGELOG.md must contain exactly one [Unreleased] compare link.')
    }

    $match = $matchList[0]
    return [pscustomobject]@{
        UnreleasedCompareLinkPrefix = $match.Groups['prefix'].Value
        UnreleasedTargetReference   = $match.Groups['target'].Value
        PreviousReleaseReference    = $match.Groups['from'].Value
    }
}
