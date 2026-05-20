function Get-UnreleasedCompareLinkMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $patternList = @(
        '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/(?:compare|-/compare)/)(?<from>.+?)\.\.\.(?<target>HEAD)\s*$',
        '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/branchCompare\?baseVersion=)(?<from>.+?)(?:&|&amp;)targetVersion=(?<target>.+?)(?:&|&amp;)_a=commits\s*$'
    )
    $match = $null

    foreach ($pattern in $patternList) {
        $candidateMatch = [regex]::Match($Text, $pattern)
        if ($candidateMatch.Success) {
            $match = $candidateMatch
            break
        }
    }

    if ($null -eq $match -or -not $match.Success) {
        throw 'Could not find an [Unreleased] compare link in CHANGELOG.md.'
    }

    return $match
}
