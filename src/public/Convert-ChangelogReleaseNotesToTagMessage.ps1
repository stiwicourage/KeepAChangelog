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
