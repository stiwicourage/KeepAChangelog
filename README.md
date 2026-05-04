# <img src="https://d3vv6lp55qjaqc.cloudfront.net/items/1L1w0v431V0d1K410f3Y/keepAChangelog-logo-dark.svg" height=150 alt="KeepAChangelog" />

[![Keep a Changelog][changelog-badge]][changelog] [![PowerShell Gallery Version][version-badge]][powershellgallery] [![MIT License Badge][license-badge]][license]

Don’t let your friends dump git logs into changelogs™


# KeepAChangelog

`KeepAChangelog` is a PowerShell module for creating, validating, and releasing changelog files that follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

The GitHub Pages user manual lives in [`docs/`](./docs/) and is intended for module users. Contributor workflow and repository-maintainer guidance stay in this `README.md`.

## Iteration 1 documents

The numbered specification files for the first implementation round live in `docs/spec/`:

1. [01-iteration-1-scope.md](./docs/spec/01-iteration-1-scope.md)
2. [02-changelog-format-rules.md](./docs/spec/02-changelog-format-rules.md)
3. [03-release-workflow.md](./docs/spec/03-release-workflow.md)

PowerShell external help continues to live under `docs/KeepAChangelog/en-US/`.

## Module commands

Build the module and import it from `dist/` so you use the same output that gets tested and published:

```powershell
nova build
Import-Module ./dist/KeepAChangelog/KeepAChangelog.psd1 -Force
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

## Release automation

The repository publish workflow now follows the same branch split as `NovaModuleTools`:

- pushes to `main` use `Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests -ContinuousIntegration`
- pushes to `develop` use `Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests -ContinuousIntegration`

After the `main` release path completes, the workflow still commits the released changelog, creates the annotated version tag, and prepares the next prerelease version on `develop`.

The test workflow also imports the built module from `dist/` and runs `Test-KeepAChangelogFile -Path ./CHANGELOG.md` so the repository changelog is validated by the same command the module exposes to users.

[changelog]: ./CHANGELOG.md
[changelog-badge]: https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735
[powershellgallery]: https://www.powershellgallery.com/packages/KeepAChangelog
[license]: ./LICENSE
[version-badge]: https://img.shields.io/powershellgallery/v/KeepAChangelog
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
