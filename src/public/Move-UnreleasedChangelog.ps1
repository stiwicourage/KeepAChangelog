function Move-UnreleasedChangelog {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = 'CHANGELOG.md',

        [Parameter(Mandatory)]
        [string]$Version,

        [string]$Date,

        [string]$RepositoryUrl
    )

    dynamicparam {
        return Get-KeepAChangelogRepositoryProviderParameterDictionary `
            -IncludeRepositoryTargetReference `
            -IncludeReleaseReference
    }

    begin {
        if ([string]::IsNullOrWhiteSpace($Version)) {
            throw 'Version is required.'
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Could not find CHANGELOG file at '$Path'."
        }

        $releaseDate = Resolve-KeepAChangelogReleaseDate -Date $Date
        $releaseReference = $PSBoundParameters['ReleaseReference']
        $release = @{
            Version   = $Version
            Date      = $releaseDate
            Tag       = $Version
            Reference = if ([string]::IsNullOrWhiteSpace($releaseReference)) { $Version } else { $releaseReference }
        }

        $repositoryProvider = $PSBoundParameters['RepositoryProvider']
        $repositoryTargetReference = $PSBoundParameters['RepositoryTargetReference']
        $repositoryState = Get-KeepAChangelogRepositoryState `
            -RepositoryUrl $RepositoryUrl `
            -RepositoryProvider $repositoryProvider `
            -RepositoryTargetReference $repositoryTargetReference
        $text = Get-Content -LiteralPath $Path -Raw
        $result = Resolve-KeepAChangelogReleaseData `
            -Text $text `
            -Release $release `
            -RepositoryState $repositoryState
        $result | Add-Member -NotePropertyName KeepAChangelogVersion -NotePropertyValue (Get-KeepAChangelogModuleVersion) -Force
        $targetVersion = $result.Release.Version

        if (-not $PSCmdlet.ShouldProcess($Path, "Promote [Unreleased] to [$targetVersion]")) {
            return $result
        }

        Set-Content -LiteralPath $Path -Value $result.UpdatedText -Encoding utf8
        return $result
    }
}
