function Add-ChangelogTagMessageBlankLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$LineList,
        [Parameter(Mandatory)]
        [bool]$AllowBlankLine
    )

    if (-not $AllowBlankLine -or $LineList.Count -eq 0) {
        return $false
    }

    $LineList.Add('')
    return $false
}
