function Get-KeepAChangelogReferenceLabelCountMap {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Footer
    )

    $referenceLabelCountMap = @{}
    if ([string]::IsNullOrWhiteSpace($Footer)) {
        return $referenceLabelCountMap
    }

    foreach ($referenceMatch in [regex]::Matches($Footer, '(?m)^\[(?<label>[^\]]+)\]:')) {
        $label = $referenceMatch.Groups['label'].Value
        if (-not $referenceLabelCountMap.ContainsKey($label)) {
            $referenceLabelCountMap[$label] = 0
        }

        $referenceLabelCountMap[$label]++
    }

    return $referenceLabelCountMap
}
