function Get-UnreleasedCompareLinkMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $pattern = '(?m)^\[Unreleased\]:\s*(?<prefix>\S+/compare/)(?<from>.+?)\.\.\.HEAD\s*$'
    $match = [regex]::Match($Text, $pattern)

    if (-not $match.Success) {
        throw 'Could not find an [Unreleased] compare link in CHANGELOG.md.'
    }

    return $match
}
