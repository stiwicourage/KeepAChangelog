function Resolve-KeepAChangelogReleaseData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [hashtable]$Release,

        [string]$RepositoryUrl
    )

    $normalizedRelease = Assert-KeepAChangelogRelease -Release $Release
    $validation = Get-KeepAChangelogValidationResult -Text $Text

    if (-not $validation.IsValid) {
        throw "CHANGELOG.md is not valid. $($validation.Errors -join ' ')"
    }

    $parts = Split-KeepAChangelogText -Text $Text
    $unreleasedSectionMatch = Get-UnreleasedSectionMatch -Text $parts.Body
    $normalizedRepositoryUrl = if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        $null
    } else {
        $RepositoryUrl.TrimEnd('/')
    }
    $unreleasedCompareLinkPrefix = $validation.UnreleasedCompareLinkPrefix
    $previousReleaseReference = $validation.PreviousReleaseReference

    if ([string]::IsNullOrWhiteSpace($unreleasedCompareLinkPrefix)) {
        if ([string]::IsNullOrWhiteSpace($normalizedRepositoryUrl)) {
            throw 'RepositoryUrl is required for the first release when CHANGELOG.md has no [Unreleased] compare link.'
        }

        $unreleasedCompareLinkPrefix = "$normalizedRepositoryUrl/compare/"
    } elseif ([string]::IsNullOrWhiteSpace($normalizedRepositoryUrl)) {
        $normalizedRepositoryUrl = $unreleasedCompareLinkPrefix -replace '/compare/$', ''
    }

    $unreleasedBody = $unreleasedSectionMatch.Groups['body'].Value.Trim()
    $releaseNotesBody = Get-ChangelogReleaseNotesBody -Body $unreleasedBody
    $clearedUnreleasedBody = Get-ClearedUnreleasedBody -Body $unreleasedBody

    $unreleasedSectionLineList = [System.Collections.Generic.List[string]]::new()
    $unreleasedSectionLineList.Add('## [Unreleased]')

    if (-not [string]::IsNullOrWhiteSpace($clearedUnreleasedBody)) {
        $unreleasedSectionLineList.Add('')
        $unreleasedSectionLineList.Add($clearedUnreleasedBody)
    }

    $newReleaseSectionLineList = [System.Collections.Generic.List[string]]::new()
    $newReleaseSectionLineList.Add("## [$($normalizedRelease.Version)] - $($normalizedRelease.Date)")

    if (-not [string]::IsNullOrWhiteSpace($releaseNotesBody)) {
        $newReleaseSectionLineList.Add('')
        $newReleaseSectionLineList.Add($releaseNotesBody)
    }

    $beforeUnreleased = $parts.Body.Substring(0, $unreleasedSectionMatch.Index).TrimEnd()
    $afterUnreleasedStart = $unreleasedSectionMatch.Index + $unreleasedSectionMatch.Length
    $afterUnreleased = $parts.Body.Substring($afterUnreleasedStart).TrimStart("`r", "`n")

    $bodySectionList = [System.Collections.Generic.List[string]]::new()

    foreach ($section in @(
            $beforeUnreleased
            ($unreleasedSectionLineList -join "`n")
            ($newReleaseSectionLineList -join "`n")
            $afterUnreleased
        )) {
        if ([string]::IsNullOrWhiteSpace($section)) {
            continue
        }

        $bodySectionList.Add($section.TrimEnd())
    }

    $updatedBody = ($bodySectionList -join "`n`n").TrimEnd()
    $updatedFooterData = Get-UpdatedChangelogReferenceFooter `
        -Footer $parts.Footer `
        -ReleaseVersion $normalizedRelease.Version `
        -ReleaseTag $normalizedRelease.Tag `
        -UnreleasedCompareLinkPrefix $unreleasedCompareLinkPrefix `
        -PreviousReleaseReference $previousReleaseReference `
        -RepositoryUrl $normalizedRepositoryUrl
    $updatedText = ($updatedBody + "`n`n" + $updatedFooterData.Footer).TrimEnd() + "`n"
    $newReleaseSection = ($newReleaseSectionLineList -join "`n").TrimEnd()

    return [pscustomobject]@{
        Release                     = $normalizedRelease
        UnreleasedCompareLinkPrefix = $unreleasedCompareLinkPrefix
        PreviousReleaseReference    = $previousReleaseReference
        UnreleasedBody              = $unreleasedBody
        ReleaseNotesBody            = $releaseNotesBody
        ClearedUnreleasedBody       = $clearedUnreleasedBody
        NewReleaseSection           = $newReleaseSection
        UpdatedUnreleasedLink       = $updatedFooterData.UpdatedUnreleasedLink
        NewReleaseCompareLink       = $updatedFooterData.NewReleaseCompareLink
        NewReleaseLink              = $updatedFooterData.NewReleaseLink
        TagMessageText              = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes $releaseNotesBody
        UpdatedText                 = $updatedText
    }
}
