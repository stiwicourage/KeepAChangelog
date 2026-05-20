function Get-ChangelogReleaseTargetReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Link
    )

    $compareMatch = [regex]::Match($Link, '/(?:compare|-/compare)/.+\.\.\.(?<target>.+)$')
    if ($compareMatch.Success) {
        return $compareMatch.Groups['target'].Value
    }

    $azureCompareMatch = [regex]::Match(
        $Link,
        'branchCompare\?baseVersion=.+?(?:&|&amp;)targetVersion=(?<target>.+?)(?:&|&amp;)_a=commits$'
    )
    if ($azureCompareMatch.Success) {
        return $azureCompareMatch.Groups['target'].Value
    }

    $tagMatch = [regex]::Match($Link, '/(?:releases/tag|-/tags)/(?<target>.+)$')
    if ($tagMatch.Success) {
        return $tagMatch.Groups['target'].Value
    }

    return $null
}

function Get-KeepAChangelogPreviousReleaseReference {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Footer,
        [Parameter(Mandatory)]
        [pscustomobject]$Validation,
        [Parameter(Mandatory)]
        [pscustomobject]$Release
    )

    $previousReleaseReference = $Validation.PreviousReleaseReference
    if ([string]::IsNullOrWhiteSpace($previousReleaseReference)) {
        return $null
    }

    if ($previousReleaseReference -ne $Release.Reference) {
        return $previousReleaseReference
    }

    $referenceLinkData = Get-ChangelogReferenceLinkData -Footer $Footer
    foreach ($releaseVersion in $Validation.ReleaseVersions) {
        if (-not $referenceLinkData.LinkMap.Contains($releaseVersion)) {
            continue
        }

        $releaseTargetReference = Get-ChangelogReleaseTargetReference -Link $referenceLinkData.LinkMap[$releaseVersion]
        if (-not [string]::IsNullOrWhiteSpace($releaseTargetReference) -and $releaseTargetReference -ne $Release.Reference) {
            return $releaseTargetReference
        }
    }

    return $null
}
