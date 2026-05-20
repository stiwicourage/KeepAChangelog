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

function Get-ChangelogReleaseLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,
        [AllowEmptyString()]
        [string]$PreviousReleaseReference,
        [Parameter(Mandatory)]
        [string]$ReleaseReference
    )

    if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        if (-not [string]::IsNullOrWhiteSpace($Context.ReleaseTagPrefix)) {
            return "$($Context.ReleaseTagPrefix)$ReleaseReference"
        }

        return Get-KeepAChangelogCompareLink `
            -RepositoryLinkData $Context `
            -BaseReference $ReleaseReference `
            -TargetReference $ReleaseReference
    }

    return Get-KeepAChangelogCompareLink `
        -RepositoryLinkData $Context `
        -BaseReference $PreviousReleaseReference `
        -TargetReference $ReleaseReference
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

    $shouldWriteReferenceFooter = $true
    if ($Context.PSObject.Properties.Name -contains 'ShouldWriteReferenceFooter') {
        $shouldWriteReferenceFooter = [bool]$Context.ShouldWriteReferenceFooter
    }

    if (-not $shouldWriteReferenceFooter) {
        return [pscustomobject]@{
            Footer               = ''
            UpdatedUnreleasedLink = $null
            NewReleaseCompareLink = $null
            NewReleaseLink        = $null
        }
    }

    $referenceLinkData = Get-ChangelogReferenceLinkData -Footer $Footer
    $orderedLabelList = $referenceLinkData.OrderedLabelList
    $linkMap = $referenceLinkData.LinkMap

    if (-not $linkMap.Contains('Unreleased')) {
        $orderedLabelList.Add('Unreleased')
    }

    $updatedUnreleasedLink = Get-KeepAChangelogCompareLink `
        -RepositoryLinkData $Context `
        -BaseReference $Release.Reference `
        -TargetReference $Context.UnreleasedTargetReference
    $newReleaseLink = Get-ChangelogReleaseLink `
        -Context $Context `
        -PreviousReleaseReference $Context.PreviousReleaseReference `
        -ReleaseReference $Release.Reference
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
