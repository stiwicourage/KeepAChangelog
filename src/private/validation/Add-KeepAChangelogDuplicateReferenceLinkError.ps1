function Add-KeepAChangelogDuplicateReferenceLinkError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ReferenceLabelCountMap,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ErrorList
    )

    foreach ($label in $ReferenceLabelCountMap.Keys) {
        if ($ReferenceLabelCountMap[$label] -le 1) {
            continue
        }

        $ErrorList.Add("Reference link [$label] is duplicated.")
    }
}
