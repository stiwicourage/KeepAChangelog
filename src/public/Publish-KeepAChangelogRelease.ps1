function Publish-KeepAChangelogRelease {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = 'CHANGELOG.md',

        [Parameter(Mandatory)]
        [hashtable]$Release,

        [string]$RepositoryUrl
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Could not find CHANGELOG file at '$Path'."
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $result = Resolve-KeepAChangelogReleaseData -Text $text -Release $Release -RepositoryUrl $RepositoryUrl
    $targetVersion = $result.Release.Version

    if (-not $PSCmdlet.ShouldProcess($Path, "Promote [Unreleased] to [$targetVersion]")) {
        return $result
    }

    Set-Content -LiteralPath $Path -Value $result.UpdatedText -Encoding utf8
    return $result
}
