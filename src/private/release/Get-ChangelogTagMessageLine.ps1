function Get-ChangelogTagMessageLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TrimmedLine
    )

    if ($TrimmedLine -match '^###\s+(?<value>.+)$') {
        return $Matches.value
    }

    if ($TrimmedLine -match '^(?:-|\*)\s+(?<value>.+)$') {
        return $Matches.value
    }

    return $TrimmedLine
}
