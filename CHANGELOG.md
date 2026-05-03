# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed
- Changed CI so pull requests now run a dedicated CodeScene coverage-gate check against the generated Cobertura artifact, while keeping the existing develop/manual coverage upload and analysis flow.

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
