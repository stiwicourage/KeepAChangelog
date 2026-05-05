function Assert-KeepAChangelogValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Validation
    )

    if (-not $Validation.IsValid) {
        throw "CHANGELOG.md is not valid. $($Validation.Errors -join ' ')"
    }
}

function Get-KeepAChangelogRepositoryContext {
    [CmdletBinding()]
    param(
        [string]$RepositoryUrl,
        [AllowEmptyString()]
        [string]$Footer,
        [Parameter(Mandatory)]
        [pscustomobject]$Release,
        [Parameter(Mandatory)]
        [pscustomobject]$Validation
    )

    $normalizedRepositoryUrl = if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        $null
    }
    else {
        $RepositoryUrl.TrimEnd('/')
    }

    $unreleasedCompareLinkPrefix = $Validation.UnreleasedCompareLinkPrefix
    if ([string]::IsNullOrWhiteSpace($unreleasedCompareLinkPrefix)) {
        if ([string]::IsNullOrWhiteSpace($normalizedRepositoryUrl)) {
            throw 'RepositoryUrl is required for the first release when CHANGELOG.md has no [Unreleased] compare link.'
        }

        $unreleasedCompareLinkPrefix = "$normalizedRepositoryUrl/compare/"
    }

    if ([string]::IsNullOrWhiteSpace($normalizedRepositoryUrl)) {
        $normalizedRepositoryUrl = $unreleasedCompareLinkPrefix -replace '/compare/$', ''
    }

    $previousReleaseReference = Get-KeepAChangelogPreviousReleaseReference `
        -Footer $Footer `
        -Validation $Validation `
        -Release $Release

    return [pscustomobject]@{
        RepositoryUrl               = $normalizedRepositoryUrl
        UnreleasedCompareLinkPrefix = $unreleasedCompareLinkPrefix
        PreviousReleaseReference    = $previousReleaseReference
    }
}

function Get-KeepAChangelogSectionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Heading,
        [AllowEmptyString()]
        [string]$Body
    )

    if ([string]::IsNullOrWhiteSpace($Body)) {
        return $Heading
    }

    return "$Heading`n`n$Body"
}

function Get-UpdatedChangelogBodyText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Parts,
        [Parameter(Mandatory)]
        [System.Text.RegularExpressions.Match]$UnreleasedSectionMatch,
        [Parameter(Mandatory)]
        [string]$UnreleasedSection,
        [Parameter(Mandatory)]
        [string]$ReleaseSection
    )

    $beforeUnreleased = $Parts.Body.Substring(0, $UnreleasedSectionMatch.Index).TrimEnd()
    $afterUnreleasedStart = $UnreleasedSectionMatch.Index + $UnreleasedSectionMatch.Length
    $afterUnreleased = $Parts.Body.Substring($afterUnreleasedStart).TrimStart("`r", "`n")

    return (@(
            $beforeUnreleased
            $UnreleasedSection
            $ReleaseSection
            $afterUnreleased
        ) |
        Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
        ForEach-Object {$_.TrimEnd()} |
        Join-String -Separator "`n`n").TrimEnd()
}

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
    Assert-KeepAChangelogValidation -Validation $validation
    $parts = Split-KeepAChangelogText -Text $Text
    Assert-KeepAChangelogReleaseDateOrder -Body $parts.Body -Release $normalizedRelease
    $unreleasedSectionMatch = Get-UnreleasedSectionMatch -Text $parts.Body
    $repositoryContext = Get-KeepAChangelogRepositoryContext `
        -RepositoryUrl $RepositoryUrl `
        -Footer $parts.Footer `
        -Release $normalizedRelease `
        -Validation $validation
    $unreleasedBody = $unreleasedSectionMatch.Groups['body'].Value.Trim()
    $releaseNotesBody = Get-ChangelogReleaseNotesBody -Body $unreleasedBody
    $clearedUnreleasedBody = Get-ClearedUnreleasedBody -Body $unreleasedBody
    $unreleasedSection = Get-KeepAChangelogSectionText -Heading '## [Unreleased]' -Body $clearedUnreleasedBody
    $newReleaseSection = Get-KeepAChangelogSectionText -Heading "## [$($normalizedRelease.Version)] - $($normalizedRelease.Date)" -Body $releaseNotesBody
    $updatedBody = Get-UpdatedChangelogBodyText `
        -Parts $parts `
        -UnreleasedSectionMatch $unreleasedSectionMatch `
        -UnreleasedSection $unreleasedSection `
        -ReleaseSection $newReleaseSection
    $updatedFooterData = Get-UpdatedChangelogReferenceFooter `
        -Footer $parts.Footer `
        -Release $normalizedRelease `
        -Context $repositoryContext
    $updatedText = ($updatedBody + "`n`n" + $updatedFooterData.Footer).TrimEnd() + "`n"

    return [pscustomobject]@{
        Release                     = $normalizedRelease
        UnreleasedCompareLinkPrefix = $repositoryContext.UnreleasedCompareLinkPrefix
        PreviousReleaseReference    = $repositoryContext.PreviousReleaseReference
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
