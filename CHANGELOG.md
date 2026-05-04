# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added a GitHub Pages user manual in `docs/` for people using the `KeepAChangelog` module, with the keep-a-changelog style header and original footer wording/layout, original browser-default language dropdown sizing, independently aligned version and changelog panel placement, adjusted first-section spacing, and a changelog panel that shows the current project `CHANGELOG.md` with adjusted typography and without changing the hero background height. The site now uses a feature-overview section for the KeepAChangelog module, a dedicated installation and command guide for the public commands, a CI/CD guide in the effort section with example links to the repository workflows, and the version derived from `CHANGELOG.md` to point the index-page version link at the matching PowerShell Gallery package URL.

### Changed
- Changed CI so pull requests now run a dedicated CodeScene coverage-gate check against a Cobertura report generated from the built module, remapped back to `src/`, and validated against the full module source surface, while keeping the existing develop/manual coverage upload and analysis flow.
- Changed publish automation so pushes to `main` now release through `Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests -ContinuousIntegration`, while pushes to `develop` keep using `Publish-NovaModule` for the prerelease publish path.
- Changed the test workflow so it now imports the built module from `dist/` and validates the repository `CHANGELOG.md` with `Test-KeepAChangelogFile`.

### Deprecated

### Removed

### Fixed

### Security

## [0.1.1] - 2026-05-02

### Added

- Created command `Initialize-KeepAChangelogFile`, allowed without `-PreviousReleaseReference`, and documented `main` and `develop` as valid previous refs.
- Created command `Move-UnreleasedChangelog`, `-Version` is required release input, and `-Date` is optional with `yyyy-MM-dd` validation.

[Unreleased]: https://github.com/stiwicourage/KeepAChangelog/compare/0.1.1...HEAD
[0.1.1]: https://github.com/stiwicourage/KeepAChangelog/compare/103d84a...0.1.1
