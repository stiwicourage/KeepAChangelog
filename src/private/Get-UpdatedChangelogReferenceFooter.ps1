function Get-ChangelogReferenceLinkData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Footer
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

    return [pscustomobject]@{
        OrderedLabelList = $orderedLabelList
        LinkMap          = $linkMap
    }
}

function Get-NormalizedChangelogRepositoryUrl {
    [CmdletBinding()]
    param(
        [string]$RepositoryUrl,
        [Parameter(Mandatory)]
        [string]$UnreleasedCompareLinkPrefix
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        return ($UnreleasedCompareLinkPrefix -replace '/compare/$', '')
    }

    return $RepositoryUrl.TrimEnd('/')
}

function Get-ChangelogReleaseLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryUrl,
        [Parameter(Mandatory)]
        [string]$UnreleasedCompareLinkPrefix,
        [AllowEmptyString()]
        [string]$PreviousReleaseReference,
        [Parameter(Mandatory)]
        [string]$ReleaseTag
    )

    if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        return "$RepositoryUrl/releases/tag/$ReleaseTag"
    }

    return "$UnreleasedCompareLinkPrefix$PreviousReleaseReference...$ReleaseTag"
}

function Add-ChangelogReferenceLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[string]]$OrderedLabelList,
        [Parameter(Mandatory)]
        [hashtable]$LinkMap,
        [Parameter(Mandatory)]
        [string]$Label
    )

    if ($LinkMap.Contains($Label)) {
        return
    }

    $OrderedLabelList.Insert($OrderedLabelList.IndexOf('Unreleased') + 1, $Label)
}

function Get-UpdatedChangelogReferenceFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Footer,

        [Parameter(Mandatory)]
        [pscustomobject]$Release,

        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $referenceLinkData = Get-ChangelogReferenceLinkData -Footer $Footer
    $orderedLabelList = $referenceLinkData.OrderedLabelList
    $linkMap = $referenceLinkData.LinkMap

    if (-not $linkMap.Contains('Unreleased')) {
        $orderedLabelList.Add('Unreleased')
    }

    $normalizedRepositoryUrl = Get-NormalizedChangelogRepositoryUrl `
        -RepositoryUrl $Context.RepositoryUrl `
        -UnreleasedCompareLinkPrefix $Context.UnreleasedCompareLinkPrefix
    $updatedUnreleasedLink = "$($Context.UnreleasedCompareLinkPrefix)$($Release.Tag)...HEAD"
    $newReleaseLink = Get-ChangelogReleaseLink `
        -RepositoryUrl $normalizedRepositoryUrl `
        -UnreleasedCompareLinkPrefix $Context.UnreleasedCompareLinkPrefix `
        -PreviousReleaseReference $Context.PreviousReleaseReference `
        -ReleaseTag $Release.Tag
    $linkMap['Unreleased'] = $updatedUnreleasedLink

    Add-ChangelogReferenceLabel -OrderedLabelList $orderedLabelList -LinkMap $linkMap -Label $Release.Version
    $linkMap[$Release.Version] = $newReleaseLink

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
