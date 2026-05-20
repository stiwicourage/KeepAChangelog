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
        'https://github.com/example/repo/releases/tag/1.0.0'
        'https://gitlab.com/example/repo/-/tags/1.0.0'
    ) {
        $result = Get-ChangelogReleaseTargetReference -Link $_

        $result | Should -Be '1.0.0'
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
                Tag = '1.0.0'
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
                Tag = '1.0.0'
            })

        $result | Should -BeNullOrEmpty
    }
}
