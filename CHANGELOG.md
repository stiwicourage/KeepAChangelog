# Changelog

All notable changes to this project will be documented in this file and **PREVIEW / UNRELEASED** changes will be included in the next **stable** release!

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.2.1] - 2026-05-06

### Fixed

- Moved the internal `Convert-ChangelogReleaseNotesToTagMessage` helper functions into `src/private/release` so every `src/public` file now contains exactly one top-level function and CI no longer needs the temporary `Invoke-NovaBuild -OverrideWarning` workaround.

## [0.2.0] - 2026-05-05

### Added

- Added `Get-KeepAChangelogVersion` and included `KeepAChangelogVersion` in `Move-UnreleasedChangelog` output so CI logs and bug reports show which module version produced the result.

### Changed

- Reworked `README.md` into a maintainer guide that explains the repository layout, local quality flow, CI/CD workflows, ScriptAnalyzer usage, CodeScene usage, release automation, and documentation ownership for the upcoming `1.0.0` release line.
- Moved the `Initialize-KeepAChangelogFile` internal helper functions into `src/private/initialize` so the initialization workflow follows the same private-helper structure as the rest of the module.

### Fixed

- Refactored the internal changelog validation helper into smaller private functions so the validation workflow keeps the same behavior while reducing method size and complexity ahead of `1.0.0`.
- Fixed `Move-UnreleasedChangelog` so re-releasing the same version after moving its notes back into `Unreleased` reuses the real previous release reference instead of generating a self-compare link.
- Fixed `Move-UnreleasedChangelog` so a new release date cannot be earlier than the latest existing release date in `CHANGELOG.md`, while still allowing first releases and same-day releases.

## [0.1.2] - 2026-05-04

### Added

- Added a GitHub Pages user manual in `docs/` for people using the `KeepAChangelog` module, with the original keep-a-changelog style, and a changelog panel that shows the current project `CHANGELOG.md`. The site now uses a feature-overview section for the KeepAChangelog module, a dedicated installation and command guide for the public commands, a CI/CD guide in the effort section with example links to the repository workflows, and the version derived from `CHANGELOG.md` to point the index-page version link at the matching PowerShell Gallery package URL.

### Changed

- Changed the `README.md` badges so the changelog-format badge is stable and the version badge is pulled dynamically from PowerShell Gallery instead of hardcoding a released version.

## [0.1.1] - 2026-05-02

### Added

- Created command `Initialize-KeepAChangelogFile`, allowed without `-PreviousReleaseReference`, and documented `main` and `develop` as valid previous refs.
- Created command `Move-UnreleasedChangelog`, `-Version` is required release input, and `-Date` is optional with `yyyy-MM-dd` validation.

[Unreleased]: https://github.com/stiwicourage/KeepAChangelog/compare/0.2.1...HEAD
[0.2.1]: https://github.com/stiwicourage/KeepAChangelog/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/stiwicourage/KeepAChangelog/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/stiwicourage/KeepAChangelog/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/stiwicourage/KeepAChangelog/compare/103d84a...0.1.1

