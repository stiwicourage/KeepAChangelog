function Get-KeepAChangelogRepositoryState {
    [CmdletBinding()]
    param(
        [string]$RepositoryUrl,
        [string]$RepositoryProvider,
        [string]$RepositoryTargetReference,
        [AllowEmptyString()]
        [string]$Footer
    )

    return [pscustomobject]@{
        Footer                    = $Footer
        RepositoryProvider        = $RepositoryProvider
        RepositoryTargetReference = $RepositoryTargetReference
        RepositoryUrl             = $RepositoryUrl
    }
}

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
        [Parameter(Mandatory)]
        [pscustomobject]$RepositoryState,
        [Parameter(Mandatory)]
        [pscustomobject]$Release,
        [Parameter(Mandatory)]
        [pscustomobject]$Validation
    )

    $normalizedRepositoryUrl = if ([string]::IsNullOrWhiteSpace($RepositoryState.RepositoryUrl)) {
        $null
    }
    else {
        $RepositoryState.RepositoryUrl.TrimEnd('/')
    }

    $unreleasedCompareLinkPrefix = $Validation.UnreleasedCompareLinkPrefix
    $shouldWriteReferenceFooter = (-not [string]::IsNullOrWhiteSpace($unreleasedCompareLinkPrefix)) -or `
        (-not [string]::IsNullOrWhiteSpace($normalizedRepositoryUrl))

    if (-not $shouldWriteReferenceFooter) {
        return [pscustomobject]@{
            RepositoryUrl               = $null
            UnreleasedCompareLinkPrefix = $null
            UnreleasedTargetReference   = $null
            CompareLinkPrefix           = $null
            CompareLinkSeparator        = $null
            CompareLinkSuffix           = $null
            ReleaseTagPrefix            = $null
            PreviousReleaseReference    = $null
            ShouldWriteReferenceFooter  = $false
        }
    }

    $repositoryLinkData = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
            RepositoryUrl             = $normalizedRepositoryUrl
            RepositoryProvider        = $RepositoryState.RepositoryProvider
            RepositoryTargetReference = $RepositoryState.RepositoryTargetReference
            UnreleasedCompareLinkPrefix = $unreleasedCompareLinkPrefix
            UnreleasedTargetReference = $Validation.UnreleasedTargetReference
        })

    $previousReleaseReference = Get-KeepAChangelogPreviousReleaseReference `
        -Footer $RepositoryState.Footer `
        -Validation $Validation `
        -Release $Release

    return [pscustomobject]@{
        RepositoryProvider          = $repositoryLinkData.RepositoryProvider
        RepositoryUrl               = $repositoryLinkData.RepositoryUrl
        UnreleasedCompareLinkPrefix = $repositoryLinkData.UnreleasedCompareLinkPrefix
        UnreleasedTargetReference   = $repositoryLinkData.UnreleasedTargetReference
        CompareLinkSeparator        = $repositoryLinkData.CompareLinkSeparator
        CompareLinkSuffix           = $repositoryLinkData.CompareLinkSuffix
        ReleaseTagPrefix            = $repositoryLinkData.ReleaseTagPrefix
        PreviousReleaseReference    = $previousReleaseReference
        ShouldWriteReferenceFooter  = $true
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

        [pscustomobject]$RepositoryState
    )

    $normalizedRelease = Assert-KeepAChangelogRelease -Release $Release
    $validation = Get-KeepAChangelogValidationResult -Text $Text
    Assert-KeepAChangelogValidation -Validation $validation
    $parts = Split-KeepAChangelogText -Text $Text
    Assert-KeepAChangelogReleaseDateOrder -Body $parts.Body -Release $normalizedRelease
    $unreleasedSectionMatch = Get-UnreleasedSectionMatch -Text $parts.Body
    $repositoryState = Get-KeepAChangelogRepositoryState `
        -RepositoryUrl $RepositoryState.RepositoryUrl `
        -RepositoryProvider $RepositoryState.RepositoryProvider `
        -RepositoryTargetReference $RepositoryState.RepositoryTargetReference `
        -Footer $parts.Footer
    $repositoryContext = Get-KeepAChangelogRepositoryContext `
        -RepositoryState $repositoryState `
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
    $updatedText = @(
        $updatedBody
        $updatedFooterData.Footer
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.TrimEnd() } |
        Join-String -Separator "`n`n"
    $updatedText = $updatedText.TrimEnd() + "`n"

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
