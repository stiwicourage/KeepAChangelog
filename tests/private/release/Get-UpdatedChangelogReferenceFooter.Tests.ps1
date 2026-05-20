BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-UpdatedChangelogReferenceFooter.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-UpdatedChangelogReferenceFooter' {
    It 'derives the release link from the compare prefix when RepositoryUrl is omitted' -ForEach @(
        @{
            Prefix         = 'https://github.com/example/repo/compare/'
            ReleaseTagLink = 'https://github.com/example/repo/releases/tag/1.0.0'
        }
        @{
            Prefix         = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagLink = 'https://gitlab.com/example/repo/-/tags/1.0.0'
        }
    ) {
        $result = Get-UpdatedChangelogReferenceFooter `
            -Footer '' `
            -Release ([pscustomobject]@{
                Version = '1.0.0'
                Tag     = '1.0.0'
            }) `
            -Context ([pscustomobject]@{
                RepositoryUrl               = $null
                ReleaseTagPrefix            = $ReleaseTagLink -replace '1.0.0$', ''
                UnreleasedCompareLinkPrefix = $Prefix
                PreviousReleaseReference    = ''
            })

        $result.Footer | Should -Be "[Unreleased]: $($Prefix)1.0.0...HEAD`n[1.0.0]: $ReleaseTagLink"
    }

    It 'returns an empty footer update when links should not be written' {
        $result = Get-UpdatedChangelogReferenceFooter `
            -Footer '' `
            -Release ([pscustomobject]@{
                Version = '1.0.0'
                Tag     = '1.0.0'
            }) `
            -Context ([pscustomobject]@{
                ShouldWriteReferenceFooter = $false
            })

        $result.Footer | Should -Be ''
        $result.UpdatedUnreleasedLink | Should -BeNullOrEmpty
        $result.NewReleaseCompareLink | Should -BeNullOrEmpty
        $result.NewReleaseLink | Should -BeNullOrEmpty
    }
}
