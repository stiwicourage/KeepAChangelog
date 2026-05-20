function Test-KeepAChangelogGitLabRepositoryUrl {
    [CmdletBinding()]
    param(
        [string]$RepositoryUrl
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        return $false
    }

    return $RepositoryUrl -match '^https?://[^/]*gitlab[^/]*/'
}

function Get-KeepAChangelogRepositoryProvider {
    [CmdletBinding()]
    param(
        [string]$RepositoryProvider,
        [string]$RepositoryUrl,
        [string]$UnreleasedCompareLinkPrefix
    )

    if (-not [string]::IsNullOrWhiteSpace($UnreleasedCompareLinkPrefix)) {
        if ($UnreleasedCompareLinkPrefix.TrimEnd('/') -like '*-/compare') {
            return 'GitLab'
        }

        return 'GitHub'
    }

    if (-not [string]::IsNullOrWhiteSpace($RepositoryProvider)) {
        return $RepositoryProvider
    }

    if (Test-KeepAChangelogGitLabRepositoryUrl -RepositoryUrl $RepositoryUrl) {
        return 'GitLab'
    }

    return 'GitHub'
}

function Get-KeepAChangelogComparePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryProvider
    )

    if ($RepositoryProvider -eq 'GitLab') {
        return '/-/compare/'
    }

    return '/compare/'
}

function Get-KeepAChangelogReleaseTagPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryProvider
    )

    if ($RepositoryProvider -eq 'GitLab') {
        return '/-/tags/'
    }

    return '/releases/tag/'
}

function Resolve-KeepAChangelogRepositoryUrlFromComparePrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UnreleasedCompareLinkPrefix,
        [Parameter(Mandatory)]
        [string]$ComparePath
    )

    $normalizedPrefix = $UnreleasedCompareLinkPrefix.TrimEnd('/')
    $compareSuffix = $ComparePath.TrimEnd('/')

    return $normalizedPrefix.Substring(0, $normalizedPrefix.Length - $compareSuffix.Length)
}

function Get-KeepAChangelogRepositoryLinkData {
    [CmdletBinding()]
    param(
        [string]$RepositoryUrl,
        [string]$RepositoryProvider,
        [string]$UnreleasedCompareLinkPrefix
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl) -and [string]::IsNullOrWhiteSpace($UnreleasedCompareLinkPrefix)) {
        return [pscustomobject]@{
            RepositoryProvider          = $null
            RepositoryUrl               = $null
            UnreleasedCompareLinkPrefix = $null
            ReleaseTagPrefix            = $null
        }
    }

    $normalizedRepositoryUrl = if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        $null
    }
    else {
        $RepositoryUrl.TrimEnd('/')
    }

    $resolvedRepositoryProvider = Get-KeepAChangelogRepositoryProvider `
        -RepositoryProvider $RepositoryProvider `
        -RepositoryUrl $normalizedRepositoryUrl `
        -UnreleasedCompareLinkPrefix $UnreleasedCompareLinkPrefix
    $comparePath = Get-KeepAChangelogComparePath `
        -RepositoryProvider $resolvedRepositoryProvider

    if ([string]::IsNullOrWhiteSpace($normalizedRepositoryUrl)) {
        $normalizedRepositoryUrl = Resolve-KeepAChangelogRepositoryUrlFromComparePrefix `
            -UnreleasedCompareLinkPrefix $UnreleasedCompareLinkPrefix `
            -ComparePath $comparePath
    }

    return [pscustomobject]@{
        RepositoryProvider          = $resolvedRepositoryProvider
        RepositoryUrl               = $normalizedRepositoryUrl
        UnreleasedCompareLinkPrefix = "$normalizedRepositoryUrl$comparePath"
        ReleaseTagPrefix            = "$normalizedRepositoryUrl$(Get-KeepAChangelogReleaseTagPath -RepositoryProvider $resolvedRepositoryProvider)"
    }
}
