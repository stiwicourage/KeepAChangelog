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

function Remove-ChangelogTagMessageTrailingBlanks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$LineList
    )

    while ($LineList.Count -gt 0 -and [string]::IsNullOrWhiteSpace($LineList[$LineList.Count - 1])) {
        $LineList.RemoveAt($LineList.Count - 1)
    }
}

function Convert-ChangelogReleaseNotesToTagMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ReleaseNotes
    )

    $lineList = [System.Collections.Generic.List[string]]::new()
    $allowBlankLine = $false

    foreach ($line in $ReleaseNotes -split '\r?\n') {
        $trimmedLine = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            $allowBlankLine = Add-ChangelogTagMessageBlankLine -LineList $lineList -AllowBlankLine $allowBlankLine
            continue
        }

        $lineList.Add((Get-ChangelogTagMessageLine -TrimmedLine $trimmedLine))
        $allowBlankLine = $true
    }

    Remove-ChangelogTagMessageTrailingBlanks -LineList $lineList
    return ($lineList -join "`n").Trim()
}
