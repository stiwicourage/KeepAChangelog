function Get-TrimmedChangelogTagMessageLineList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.Collections.Generic.List[string]]$LineList
    )

    $trimmedLineList = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $LineList) {
        $trimmedLineList.Add($line)
    }

    while ($trimmedLineList.Count -gt 0 -and [string]::IsNullOrWhiteSpace($trimmedLineList[$trimmedLineList.Count - 1])) {
        $trimmedLineList.RemoveAt($trimmedLineList.Count - 1)
    }

    return $trimmedLineList
}
