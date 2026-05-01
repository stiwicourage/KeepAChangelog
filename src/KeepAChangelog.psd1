@{
    RootModule        = 'KeepAChangelog.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '58cf9260-13f2-4eb0-91f2-80b1a0c41f31'
    Author            = 'Stiwi Gabriel Courage'
    CompanyName       = 'Unknown'
    Copyright         = 'Copyright (c) 2026 Stiwi Gabriel Courage'
    Description       = 'PowerShell helpers for creating, validating, and releasing Keep a Changelog files.'
    PowerShellHostVersion = '7.4'
    FunctionsToExport = @(
        'Convert-ChangelogReleaseNotesToTagMessage'
        'Initialize-KeepAChangelogFile'
        'Publish-KeepAChangelogRelease'
        'Test-KeepAChangelogFile'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('PowerShell', 'KeepAChangelog', 'Changelog', 'ReleaseNotes')
            ProjectUri   = 'https://github.com/couragedk/KeepAChangelog'
            ReleaseNotes = 'https://github.com/couragedk/KeepAChangelog/blob/main/CHANGELOG.md'
        }
    }
}
