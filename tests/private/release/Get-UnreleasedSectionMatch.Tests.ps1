BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-UnreleasedSectionMatch.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-UnreleasedSectionMatch' {
    It 'returns the Unreleased body when the section exists' {
        $result = Get-UnreleasedSectionMatch -Text @'
## [Unreleased]

### Fixed

- Fixed CLI parsing.
'@

        $result.Groups['body'].Value.Trim() | Should -Be "### Fixed`n`n- Fixed CLI parsing."
    }

    It 'throws when the Unreleased section is missing' {
        $errorMessage = $null

        try {
            Get-UnreleasedSectionMatch -Text '# Changelog'
        }
        catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }
}
