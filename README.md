# KeepAChangelog

`KeepAChangelog` is a PowerShell module for creating, validating, and releasing changelog files that follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Iteration 1 documents

The numbered specification files for the first implementation round live in `docs/spec/`:

1. [01-iteration-1-scope.md](./docs/spec/01-iteration-1-scope.md)
2. [02-changelog-format-rules.md](./docs/spec/02-changelog-format-rules.md)
3. [03-release-workflow.md](./docs/spec/03-release-workflow.md)

PowerShell external help continues to live under `docs/KeepAChangelog/en-US/`.

## Module commands

Import the module directly from `src/` while the project is under active development:

```powershell
Import-Module ./src/KeepAChangelog.psd1 -Force
```

Available commands:

- `Initialize-KeepAChangelogFile`
- `Test-KeepAChangelogFile`
- `Move-UnreleasedChangelog`
- `Convert-ChangelogReleaseNotesToTagMessage`

## Examples

Create a new changelog template:

```powershell
Initialize-KeepAChangelogFile `
    -Path ./CHANGELOG.md `
    -RepositoryUrl https://github.com/stiwicourage/KeepAChangelog
```

Add `-PreviousReleaseReference` when the project already has a last released tag, commit SHA, or a legitimate branch ref such as `main` or `develop`:

```powershell
Initialize-KeepAChangelogFile `
    -Path ./CHANGELOG.md `
    -RepositoryUrl https://github.com/stiwicourage/KeepAChangelog `
    -PreviousReleaseReference develop
```

Validate an existing changelog:

```powershell
$result = Test-KeepAChangelogFile -Path ./CHANGELOG.md
$result.IsValid
$result.Errors
```

Promote `Unreleased` notes into a release:

```powershell
Move-UnreleasedChangelog `
    -Path ./CHANGELOG.md `
    -Version 1.6.0 `
    -Date 2026-04-30
```

If you omit `-Date`, the command uses the current date in `yyyy-MM-dd` format. If you pass `-Date`, it must use `yyyy-MM-dd`.

If this is the first release and the changelog was created without `-PreviousReleaseReference`, pass `-RepositoryUrl` so the first footer links can be added:

```powershell
Move-UnreleasedChangelog `
    -Path ./CHANGELOG.md `
    -Version 1.0.0 `
    -RepositoryUrl https://github.com/stiwicourage/KeepAChangelog
```
