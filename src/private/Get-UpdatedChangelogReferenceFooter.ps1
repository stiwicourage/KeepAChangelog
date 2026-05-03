function Get-UpdatedChangelogReferenceFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Footer,

        [Parameter(Mandatory)]
        [string]$ReleaseVersion,

        [Parameter(Mandatory)]
        [string]$ReleaseTag,

        [Parameter(Mandatory)]
        [string]$UnreleasedCompareLinkPrefix,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$PreviousReleaseReference,

        [string]$RepositoryUrl
    )

    $orderedLabelList = [System.Collections.Generic.List[string]]::new()
    $linkMap = [ordered]@{}

    foreach ($referenceMatch in [regex]::Matches($Footer, '(?m)^\[(?<label>[^\]]+)\]:\s*(?<url>\S.*?)\s*$')) {
        $label = $referenceMatch.Groups['label'].Value
        $url = $referenceMatch.Groups['url'].Value.Trim()

        if (-not $linkMap.Contains($label)) {
            $orderedLabelList.Add($label)
        }

        $linkMap[$label] = $url
    }

    if (-not $linkMap.Contains('Unreleased')) {
        $orderedLabelList.Insert(0, 'Unreleased')
    }

    $normalizedRepositoryUrl = if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        $UnreleasedCompareLinkPrefix -replace '/compare/$', ''
    } else {
        $RepositoryUrl.TrimEnd('/')
    }
    $updatedUnreleasedLink = "$UnreleasedCompareLinkPrefix$ReleaseTag...HEAD"
    $newReleaseLink = if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        "$normalizedRepositoryUrl/releases/tag/$ReleaseTag"
    } else {
        "$UnreleasedCompareLinkPrefix$PreviousReleaseReference...$ReleaseTag"
    }
    $linkMap['Unreleased'] = $updatedUnreleasedLink

    if (-not $linkMap.Contains($ReleaseVersion)) {
        $unreleasedIndex = $orderedLabelList.IndexOf('Unreleased')
        $orderedLabelList.Insert($unreleasedIndex + 1, $ReleaseVersion)
    }

    $linkMap[$ReleaseVersion] = $newReleaseLink

    $footerLineList = foreach ($label in $orderedLabelList) {
        "[$label]: $($linkMap[$label])"
    }

    return [pscustomobject]@{
        Footer               = ($footerLineList -join "`n").TrimEnd()
        UpdatedUnreleasedLink = $updatedUnreleasedLink
        NewReleaseCompareLink = $newReleaseLink
        NewReleaseLink        = $newReleaseLink
    }
}
