function Test-KeepAChangelogRepositoryUrlMatch {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$RepositoryUrl,

        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        return $false
    }

    return $RepositoryUrl -match $Pattern
}

function Test-KeepAChangelogGitLabRepositoryUrl {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$RepositoryUrl
    )

    return Test-KeepAChangelogRepositoryUrlMatch -RepositoryUrl $RepositoryUrl -Pattern 'https?://[^/]*gitlab[^/]*/'
}

function Test-KeepAChangelogAzureDevOpsRepositoryUrl {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$RepositoryUrl
    )

    return Test-KeepAChangelogRepositoryUrlMatch -RepositoryUrl $RepositoryUrl -Pattern '/_git/'
}

function Get-KeepAChangelogRepositoryProviderSetting {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GitHub', 'GitLab', 'AzureDevOps')]
        [string]$RepositoryProvider
    )

    $settingsByProvider = @{
        GitHub = [pscustomobject]@{
            CompareLinkPrefixSegment      = '/compare/'
            CompareLinkSeparator          = '...'
            CompareLinkSuffix             = ''
            DefaultUnreleasedTargetReference = 'HEAD'
            ReleaseTagPath                = '/releases/tag/'
        }
        GitLab = [pscustomobject]@{
            CompareLinkPrefixSegment      = '/-/compare/'
            CompareLinkSeparator          = '...'
            CompareLinkSuffix             = ''
            DefaultUnreleasedTargetReference = 'HEAD'
            ReleaseTagPath                = '/-/tags/'
        }
        AzureDevOps = [pscustomobject]@{
            CompareLinkPrefixSegment      = '/branchCompare?baseVersion='
            CompareLinkSeparator          = '&targetVersion='
            CompareLinkSuffix             = '&_a=commits'
            DefaultUnreleasedTargetReference = $null
            ReleaseTagPath                = $null
        }
    }

    return $settingsByProvider[$RepositoryProvider]
}

function Get-KeepAChangelogRepositoryProviderFromComparePrefix {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$UnreleasedCompareLinkPrefix
    )

    if ([string]::IsNullOrWhiteSpace($UnreleasedCompareLinkPrefix)) {
        return $null
    }

    if ($UnreleasedCompareLinkPrefix -like '*/branchCompare?baseVersion=*') {
        return 'AzureDevOps'
    }

    if ($UnreleasedCompareLinkPrefix -like '*-/compare/*') {
        return 'GitLab'
    }

    return 'GitHub'
}

function Get-KeepAChangelogRepositoryProviderFromUrl {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$RepositoryUrl
    )

    if (Test-KeepAChangelogAzureDevOpsRepositoryUrl -RepositoryUrl $RepositoryUrl) {
        return 'AzureDevOps'
    }

    if (Test-KeepAChangelogGitLabRepositoryUrl -RepositoryUrl $RepositoryUrl) {
        return 'GitLab'
    }

    return 'GitHub'
}

function Get-KeepAChangelogRepositoryProvider {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$RepositoryUrl,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$RepositoryProvider,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$UnreleasedCompareLinkPrefix
    )

    $detectedProvider = Get-KeepAChangelogRepositoryProviderFromComparePrefix -UnreleasedCompareLinkPrefix $UnreleasedCompareLinkPrefix
    if ($null -ne $detectedProvider) {
        return $detectedProvider
    }

    if (-not [string]::IsNullOrWhiteSpace($RepositoryProvider)) {
        return $RepositoryProvider
    }

    return Get-KeepAChangelogRepositoryProviderFromUrl -RepositoryUrl $RepositoryUrl
}

function Get-KeepAChangelogUnreleasedTargetReference {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GitHub', 'GitLab', 'AzureDevOps')]
        [string]$RepositoryProvider,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$RepositoryTargetReference,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$UnreleasedTargetReference
    )

    if (-not [string]::IsNullOrWhiteSpace($UnreleasedTargetReference)) {
        return $UnreleasedTargetReference
    }

    if (-not [string]::IsNullOrWhiteSpace($RepositoryTargetReference)) {
        return $RepositoryTargetReference
    }

    return (Get-KeepAChangelogRepositoryProviderSetting -RepositoryProvider $RepositoryProvider).DefaultUnreleasedTargetReference
}

function Resolve-KeepAChangelogRepositoryUrlFromComparePrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UnreleasedCompareLinkPrefix,

        [Parameter(Mandatory = $true)]
        [ValidateSet('GitHub', 'GitLab', 'AzureDevOps')]
        [string]$RepositoryProvider
    )

    $compareLinkPrefixSegment = (Get-KeepAChangelogRepositoryProviderSetting -RepositoryProvider $RepositoryProvider).CompareLinkPrefixSegment
    return $UnreleasedCompareLinkPrefix.Substring(0, $UnreleasedCompareLinkPrefix.Length - $compareLinkPrefixSegment.Length)
}

function Get-KeepAChangelogCompareLink {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RepositoryLinkData,

        [Parameter(Mandatory = $true)]
        [string]$BaseReference,

        [Parameter(Mandatory = $true)]
        [string]$TargetReference
    )

    return '{0}{1}{2}{3}{4}' -f `
        $RepositoryLinkData.UnreleasedCompareLinkPrefix, `
        $BaseReference, `
        $RepositoryLinkData.CompareLinkSeparator, `
        $TargetReference, `
        $RepositoryLinkData.CompareLinkSuffix
}

function Get-KeepAChangelogRepositoryLinkData {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RepositoryState
    )

    $repositoryUrl = $RepositoryState.RepositoryUrl
    $repositoryProvider = $RepositoryState.RepositoryProvider
    $repositoryTargetReference = $RepositoryState.RepositoryTargetReference
    $unreleasedCompareLinkPrefix = $RepositoryState.UnreleasedCompareLinkPrefix
    $unreleasedTargetReference = $RepositoryState.UnreleasedTargetReference

    if ([string]::IsNullOrWhiteSpace($repositoryUrl) -and [string]::IsNullOrWhiteSpace($unreleasedCompareLinkPrefix)) {
        return $null
    }

    $resolvedProvider = Get-KeepAChangelogRepositoryProvider `
        -RepositoryUrl $repositoryUrl `
        -RepositoryProvider $repositoryProvider `
        -UnreleasedCompareLinkPrefix $unreleasedCompareLinkPrefix
    $providerSettings = Get-KeepAChangelogRepositoryProviderSetting -RepositoryProvider $resolvedProvider

    if ([string]::IsNullOrWhiteSpace($repositoryUrl)) {
        $repositoryUrl = Resolve-KeepAChangelogRepositoryUrlFromComparePrefix `
            -UnreleasedCompareLinkPrefix $unreleasedCompareLinkPrefix `
            -RepositoryProvider $resolvedProvider
    }

    if ([string]::IsNullOrWhiteSpace($unreleasedCompareLinkPrefix)) {
        $unreleasedCompareLinkPrefix = '{0}{1}' -f $repositoryUrl, $providerSettings.CompareLinkPrefixSegment
    }

    $resolvedTargetReference = Get-KeepAChangelogUnreleasedTargetReference `
        -RepositoryProvider $resolvedProvider `
        -RepositoryTargetReference $repositoryTargetReference `
        -UnreleasedTargetReference $unreleasedTargetReference

    if (($resolvedProvider -eq 'AzureDevOps') -and [string]::IsNullOrWhiteSpace($resolvedTargetReference)) {
        throw 'RepositoryTargetReference is required when AzureDevOps footer links must be generated.'
    }

    $releaseTagPrefix = $null
    if ($null -ne $providerSettings.ReleaseTagPath) {
        $releaseTagPrefix = '{0}{1}' -f $repositoryUrl, $providerSettings.ReleaseTagPath
    }

    return [pscustomobject]@{
        RepositoryUrl            = $repositoryUrl
        RepositoryProvider       = $resolvedProvider
        UnreleasedCompareLinkPrefix = $unreleasedCompareLinkPrefix
        CompareLinkSeparator     = $providerSettings.CompareLinkSeparator
        CompareLinkSuffix        = $providerSettings.CompareLinkSuffix
        UnreleasedTargetReference = $resolvedTargetReference
        ReleaseTagPrefix         = $releaseTagPrefix
    }
}
