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
