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
            if ($allowBlankLine -and $lineList.Count -gt 0) {
                $lineList.Add('')
                $allowBlankLine = $false
            }

            continue
        }

        if ($trimmedLine -match '^###\s+(?<value>.+)$') {
            $lineList.Add($Matches.value)
            $allowBlankLine = $true
            continue
        }

        if ($trimmedLine -match '^(?:-|\*)\s+(?<value>.+)$') {
            $lineList.Add($Matches.value)
            $allowBlankLine = $true
            continue
        }

        $lineList.Add($trimmedLine)
        $allowBlankLine = $true
    }

    while ($lineList.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lineList[$lineList.Count - 1])) {
        $lineList.RemoveAt($lineList.Count - 1)
    }

    return ($lineList -join "`n").Trim()
}
