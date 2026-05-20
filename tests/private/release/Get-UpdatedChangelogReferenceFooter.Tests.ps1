BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
        'src/private/release/Get-UpdatedChangelogReferenceFooter.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-UpdatedChangelogReferenceFooter' {
    It 'derives the release link from the compare prefix when RepositoryUrl is omitted' -ForEach @(
        @{
            Prefix         = 'https://github.com/example/repo/compare/'
            ReleaseTagLink = 'https://github.com/example/repo/releases/tag/1.0.0'
            Target         = 'HEAD'
        }
        @{
            Prefix         = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagLink = 'https://gitlab.com/example/repo/-/tags/1.0.0'
            Target         = 'HEAD'
        }
        @{
            Prefix         = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
            ReleaseTagLink = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv1.0.0&targetVersion=GTv1.0.0&_a=commits'
            Target         = 'GBdevelop'
        }
    ) {
        $result = Get-UpdatedChangelogReferenceFooter `
            -Footer '' `
            -Release ([pscustomobject]@{
                Version   = '1.0.0'
                Tag       = '1.0.0'
                Reference = if ($ReleaseTagLink -like '*GTv1.0.0*') { 'GTv1.0.0' } else { '1.0.0' }
            }) `
            -Context ([pscustomobject]@{
                RepositoryUrl               = $null
                CompareLinkPrefix           = $Prefix
                CompareLinkSeparator        = if ($Prefix -like '*branchCompare?baseVersion=*') { '&targetVersion=' } else { '...' }
                CompareLinkSuffix           = if ($Prefix -like '*branchCompare?baseVersion=*') { '&_a=commits' } else { '' }
                ReleaseTagPrefix            = if ($Prefix -like '*branchCompare?baseVersion=*') { $null } else { $ReleaseTagLink -replace '1.0.0$', '' }
                UnreleasedCompareLinkPrefix = $Prefix
                UnreleasedTargetReference   = $Target
                PreviousReleaseReference    = ''
            })

        if ($Prefix -like '*branchCompare?baseVersion=*') {
            $result.Footer | Should -Be "[Unreleased]: $($Prefix)GTv1.0.0&targetVersion=GBdevelop&_a=commits`n[1.0.0]: $ReleaseTagLink"
            return
        }

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
