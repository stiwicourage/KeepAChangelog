function Initialize-KeepAChangelogFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = 'CHANGELOG.md',

        [Parameter(Mandatory)]
        [string]$RepositoryUrl,

        [string]$PreviousReleaseReference,

        [string[]]$SectionHeading = @('Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security'),

        [switch]$Force
    )

    dynamicparam {
        return Get-KeepAChangelogRepositoryProviderParameterDictionary
    }

    begin {
        Assert-KeepAChangelogInitialization -Path $Path -RepositoryUrl $RepositoryUrl -Force $Force.IsPresent
        $normalizedRepositoryUrl = $RepositoryUrl.TrimEnd('/')
        $repositoryProvider = $PSBoundParameters['RepositoryProvider']
        $template = Get-KeepAChangelogTemplateText `
            -RepositoryUrl $normalizedRepositoryUrl `
            -RepositoryProvider $repositoryProvider `
            -PreviousReleaseReference $PreviousReleaseReference `
            -SectionHeading $SectionHeading

        if (-not $PSCmdlet.ShouldProcess($Path, 'Initialize Keep a Changelog template')) {
            return
        }

        Set-Content -LiteralPath $Path -Value $template -Encoding utf8

        return [pscustomobject]@{
            Path                     = $Path
            RepositoryUrl            = $normalizedRepositoryUrl
            PreviousReleaseReference = if ([string]::IsNullOrWhiteSpace($PreviousReleaseReference)) { $null } else { $PreviousReleaseReference }
        }
    }
}
