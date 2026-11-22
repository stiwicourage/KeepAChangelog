function Get-ChangelogTagMessageLine {
    [CmdletBinding()]
    [OutputType([string])]
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
