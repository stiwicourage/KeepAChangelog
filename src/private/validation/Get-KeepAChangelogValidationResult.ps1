function Get-KeepAChangelogValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $errorList = [System.Collections.Generic.List[string]]::new()
    $parts = Split-KeepAChangelogText -Text $Text
    if (-not (Test-KeepAChangelogHasUnreleasedSection -Body $parts.Body)) {
        $errorList.Add('Could not find ## [Unreleased] section in CHANGELOG.md.')
    }

    $releaseVersionList = Get-KeepAChangelogReleaseVersionList `
        -Body $parts.Body `
        -ErrorList $errorList
    $hasReferenceFooter = -not [string]::IsNullOrWhiteSpace($parts.Footer)

    $referenceLabelCountMap = Get-KeepAChangelogReferenceLabelCountMap -Footer $parts.Footer
    Add-KeepAChangelogDuplicateReferenceLinkError `
        -ReferenceLabelCountMap $referenceLabelCountMap `
        -ErrorList $errorList

    $unreleasedCompareLinkData = Get-KeepAChangelogUnreleasedCompareLinkData `
        -Footer $parts.Footer `
        -HasReferenceFooter:$hasReferenceFooter `
        -ErrorList $errorList

    return [pscustomobject]@{
        IsValid                     = ($errorList.Count -eq 0)
        Errors                      = @($errorList.ToArray())
        UnreleasedCompareLinkPrefix = $unreleasedCompareLinkData.UnreleasedCompareLinkPrefix
        PreviousReleaseReference    = $unreleasedCompareLinkData.PreviousReleaseReference
        ReleaseVersions             = @($releaseVersionList.ToArray())
    }
}
