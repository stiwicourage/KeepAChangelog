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
        PreviousReleaseReference    = $null
    }

    if (-not $HasReferenceFooter) {
        return $result
    }

    $pattern = '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/compare/)(?<from>.+?)\.\.\.HEAD\s*$'
    $matchList = [regex]::Matches($Footer, $pattern)

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
        PreviousReleaseReference    = $match.Groups['from'].Value
    }
}
