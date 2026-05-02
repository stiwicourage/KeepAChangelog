# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created command `Initialize-KeepAChangelogFile`, allowed without `-PreviousReleaseReference`, and documented `main` and `develop` as valid previous refs.
- Created command `Move-UnreleasedChangelog`, `-Version` is required release input, and `-Date` is optional with `yyyy-MM-dd` validation.

### Changed

### Deprecated

### Removed

### Fixed
- Fixed the publish workflow so PSGallery publishing initializes the PSResourceGet repository store before `Publish-NovaModule` runs on both `main` and `develop`.

### Security


[Unreleased]: https://github.com/stiwicourage/KeepAChangelog/compare/develop...HEAD
