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
        return Get-KeepAChangelogRepositoryProviderParameterDictionary
    }

    begin {
        if ([string]::IsNullOrWhiteSpace($Version)) {
            throw 'Version is required.'
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Could not find CHANGELOG file at '$Path'."
        }

        $releaseDate = Resolve-KeepAChangelogReleaseDate -Date $Date
        $release = @{
            Version = $Version
            Date    = $releaseDate
            Tag     = $Version
        }

        $repositoryProvider = $PSBoundParameters['RepositoryProvider']
        $text = Get-Content -LiteralPath $Path -Raw
        $result = Resolve-KeepAChangelogReleaseData `
            -Text $text `
            -Release $release `
            -RepositoryUrl $RepositoryUrl `
            -RepositoryProvider $repositoryProvider
        $result | Add-Member -NotePropertyName KeepAChangelogVersion -NotePropertyValue (Get-KeepAChangelogModuleVersion) -Force
        $targetVersion = $result.Release.Version

        if (-not $PSCmdlet.ShouldProcess($Path, "Promote [Unreleased] to [$targetVersion]")) {
            return $result
        }

        Set-Content -LiteralPath $Path -Value $result.UpdatedText -Encoding utf8
        return $result
    }
}
