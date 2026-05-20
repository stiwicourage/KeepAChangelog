BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-UpdatedChangelogReferenceFooter.ps1'
        'src/private/release/Get-KeepAChangelogPreviousReleaseReference.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogPreviousReleaseReference' {
    It 'extracts the target from release tag links' -ForEach @(
        @{
            Link           = 'https://github.com/example/repo/releases/tag/1.0.0'
            ExpectedTarget = '1.0.0'
        }
        @{
            Link           = 'https://gitlab.com/example/repo/-/tags/1.0.0'
            ExpectedTarget = '1.0.0'
        }
        @{
            Link           = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv0.9.0&targetVersion=GTv1.0.0&_a=commits'
            ExpectedTarget = 'GTv1.0.0'
        }
    ) {
        $result = Get-ChangelogReleaseTargetReference -Link $Link

        $result | Should -Be $ExpectedTarget
    }

    It 'returns null when a link is not a compare or tag link' {
        $result = Get-ChangelogReleaseTargetReference -Link 'https://github.com/example/repo/issues/123'

        $result | Should -BeNullOrEmpty
    }

    It 'returns the previous release reference when it differs from the release tag' {
        $result = Get-KeepAChangelogPreviousReleaseReference `
            -Footer '' `
            -Validation ([pscustomobject]@{
                PreviousReleaseReference = '0.9.0'
                ReleaseVersions          = @()
            }) `
            -Release ([pscustomobject]@{
                Tag       = '1.0.0'
                Reference = '1.0.0'
            })

        $result | Should -Be '0.9.0'
    }

    It 'returns null when no usable previous release reference can be recovered' {
        $result = Get-KeepAChangelogPreviousReleaseReference `
            -Footer @'
[0.9.0]: https://github.com/example/repo/releases/tag/1.0.0
'@ `
            -Validation ([pscustomobject]@{
                PreviousReleaseReference = '1.0.0'
                ReleaseVersions          = @('0.9.0')
            }) `
            -Release ([pscustomobject]@{
                Tag       = '1.0.0'
                Reference = '1.0.0'
            })

        $result | Should -BeNullOrEmpty
    }

    It 'returns the previous Azure DevOps release reference when it differs from the current release reference' {
        $result = Get-KeepAChangelogPreviousReleaseReference `
            -Footer @'
[13.0.3]: https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv13.0.2&targetVersion=GTv13.0.3&_a=commits
'@ `
            -Validation ([pscustomobject]@{
                PreviousReleaseReference = 'GTv13.0.4'
                ReleaseVersions          = @('13.0.3')
            }) `
            -Release ([pscustomobject]@{
                Tag       = '13.0.4'
                Reference = 'GTv13.0.4'
            })

        $result | Should -Be 'GTv13.0.3'
    }
}
