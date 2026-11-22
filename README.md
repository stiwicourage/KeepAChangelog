# <img src="https://d3vv6lp55qjaqc.cloudfront.net/items/1L1w0v431V0d1K410f3Y/keepAChangelog-logo-dark.svg" height=150 alt="KeepAChangelog" />

[![Keep a Changelog][changelog-badge]][changelog] [![PowerShell Gallery Version][version-badge]][powershellgallery]

Don’t let your friends dump git logs into changelogs™

# KeepAChangelog maintainer guide

`KeepAChangelog` is a PowerShell module for creating, validating, and releasing changelog files that follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

This `README.md` is for **maintainers and contributors**. The GitHub Pages site in [`docs/`](./docs/) is the end-user guide.

### If you are looking for end-user guides, go to [keepachangelog.ps](https://keepachangelog.ps/).

## Project goals

- keep the public module surface small and predictable
- preserve the `Keep a Changelog` structure in generated and updated `CHANGELOG.md` files
- keep automation simple enough that maintainers can run the same quality flow locally and in CI
- hold every PowerShell source file in `src/` at **Code Health 10.0**

## Where different documentation belongs

| Location | Audience | Purpose |
| --- | --- | --- |
| `README.md` | Maintainers and contributors | Repository workflow, tooling, CI/CD, release process, and quality expectations |
| `docs/index.html` and `docs/assets/` | End users | Public GitHub Pages guide for the module |
| `docs/KeepAChangelog/en-US/` | End users and PowerShell help consumers | External help build input |
| `docs/spec/` | Maintainers | Iteration and design notes that explain the initial implementation scope |
| `CHANGELOG.md` | Users and maintainers | Released and unreleased project changes |
| `SECURITY.md` | Security reporters and maintainers | Private vulnerability handling |

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/public/` | Public PowerShell commands exported by the module |
| `src/private/` | Internal helpers grouped by concern under `initialize/`, `validation/`, `release/`, and `shared/` |
| `tests/` | Pester coverage and behavior tests |
| `scripts/build/` | Maintainer-run quality scripts such as ScriptAnalyzer |
| `.github/workflows/` | Thin callers of the shared [`powershell-ci`](https://github.com/stiwicourage/powershell-ci) reusable workflows for tests, publish, and security scanning |
| `.github/dependabot.yml` | Daily Dependabot updates for the pinned `powershell-ci` release tag |
| `docs/` | End-user site, external help input, and spec docs |
| `artifacts/` | Generated reports from local and CI validation runs |
| `dist/` | Built module output produced by NovaModuleTools |

## Toolchain used in this project

| Tool | Why it is used | How maintainers use it |
| --- | --- | --- |
| `NovaModuleTools` | Builds the module, generates the manifest/help, runs the standard Nova workflows, and drives package/release automation | Run `Invoke-NovaBuild`, `Test-NovaBuild`, `Publish-NovaModule`, `Invoke-NovaRelease`, or the `nova` CLI equivalents |
| `Pester` | Behavior tests and coverage generation | Run `Invoke-NovaTest`, then `Test-NovaBuild` |
| `PSScriptAnalyzer` | Static analysis for PowerShell source, scripts, and manifest files | Run `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` |
| `CodeScene` | Coverage gates in PRs, repository analysis in CI, and file-level Code Health review | Use the CodeScene UI / IDE integration for file health checks, while the shared `Run Tests` workflow handles coverage gates, coverage upload, and analysis triggering |
| `CodeQL` | Security and code scanning on the GitHub Actions layer | Maintainers monitor the `Security` workflow and resulting alerts |
| `dependency-review-action` | Blocks PRs that introduce vulnerable dependency updates | Maintainers review the `Security` workflow dependency-review result on pull requests |
| GitHub Pages | Hosts the user guide at `keepachangelog.ps` | Maintain `docs/index.html`, `docs/assets/`, and related site content |
| PowerShell Gallery | Distribution target for stable and prerelease packages | Publishing is handled by the `Publish Module` workflow and the Nova release/publish commands |

## Prerequisites for local maintenance

The repository targets **PowerShell 7.4**. Before using the build and quality scripts locally, install the maintainer dependencies:

```powershell
Install-Module NovaModuleTools -AllowPrerelease -Scope CurrentUser
Install-Module Pester -Scope CurrentUser
Install-Module PSScriptAnalyzer -Scope CurrentUser
```

If you want the `nova` launcher locally, install it after `NovaModuleTools` is available:

```powershell
Install-NovaCli
```

## Standard maintainer workflows

### Fast local build loop

Use this when you are iterating on module code and want the built output loaded from `dist/`:

```powershell
nova build
Import-Module ./dist/KeepAChangelog/KeepAChangelog.psd1 -Force
```

The build creates the module under `dist/KeepAChangelog/`.

### Full local quality gate

`run.ps1` is the shortest path to the repository's local quality flow:

```powershell
./run.ps1
```

That script does four things in order:

1. runs `Invoke-NovaBuild`
2. runs `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
3. imports the built manifest from `dist/`
4. runs `Test-NovaBuild`

Use it before opening a pull request or after non-trivial refactors.

### Build and test commands

Use the Nova commands directly when you want more control than `run.ps1` gives you:

```powershell
Invoke-NovaBuild
Test-NovaBuild
Test-NovaBuild -Build
```

CLI equivalents:

```powershell
nova build
nova test
nova test --build
nova test -b
```

`Test-NovaBuild -Build` rebuilds the project first. Plain `Test-NovaBuild` runs the test suite against the current repo state.

### Repository changelog validation

The repository changelog is validated in CI by the same public command the module exposes:

```powershell
$result = Test-KeepAChangelogFile -Path ./CHANGELOG.md
$result.IsValid
$result.Errors
```

Use that check before changing release notes or release automation.

## Maintainer scripts and what to expect

### `scripts/build/Invoke-ScriptAnalyzerCI.ps1`

Runs the shared `powershell-ci` analyzer with the same settings as CI against:

- `src/`
- `scripts/`
- `tests/`
- `run.ps1`

Every severity, including `Information`, fails the gate; only `PSAvoidUsingWriteHost` is excluded. Generated files under `dist/` and `artifacts/` are ignored. The result is written to `artifacts/scriptanalyzer.txt`.

The wrapper needs a `powershell-ci` checkout next to this repository, or its path in `POWERSHELL_CI_PATH`.

Run it directly with:

```powershell
./scripts/build/Invoke-ScriptAnalyzerCI.ps1
```

### Shared CI from `powershell-ci`

CI build, test, coverage, changelog validation, CodeScene upload, release, and security scanning come from the reusable workflows in [`stiwicourage/powershell-ci`](https://github.com/stiwicourage/powershell-ci). This repository keeps only the thin callers in `.github/workflows/`, pinned to a released `powershell-ci` tag. Dependabot proposes a grouped `powershell-ci` update every day, without the default release cooldown.

To reproduce the CI test run locally:

```powershell
Invoke-NovaBuild
Invoke-NovaTest
Test-NovaBuild
```

Expected artifacts include `artifacts/coverage.xml` (JaCoCo) and the Nova test results.

## Code Health expectations

This repository is intentionally strict about maintainability:

- **every PowerShell source file under `src/` should stay at Code Health `10.0`**
- keep functions short and focused
- keep public commands thin and move internal logic into small helpers
- avoid duplication and comment-free dead code

The current release-readiness target for `1.0.0` is that the `src/` PowerShell files remain at `10.0`.

CodeScene is used in two different ways:

1. **file-level maintainability review** using the CodeScene product / IDE integration
2. **CI-level coverage and repository analysis** using the shared `powershell-ci` workflows

If a file drops below `10.0`, treat that as release-blocking work for the `1.0.0` line.

## GitHub Actions workflows

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `Run Tests` (`.github/workflows/Tests.yml`) | pushes except `main`, PRs to `main` and `develop`, schedule, manual dispatch | Calls `powershell-ci` `tests.yml`: analyzer, build, test, coverage, `CHANGELOG.md` and `RELEASE_NOTE.md` validation, CodeScene coverage gates, and CodeScene analysis |
| `Publish Module` (`.github/workflows/Publish.yml`) | pushes to `main`, manual dispatch | Calls `powershell-ci` `publish.yml`: stable release, changelog and release-note promotion, release tag, GitHub release, and prerelease-prep commits |
| `Security` (`.github/workflows/Security.yml`) | pushes to `develop`, PRs to `develop`, weekly schedule | Calls `powershell-ci` CodeQL, PSScriptAnalyzer SARIF, and PR-only dependency review |

## Release and branch workflow

`CHANGELOG.md` is the exhaustive change record and `RELEASE_NOTE.md` is the user-facing summary. The release automation expects `## [Unreleased]` in both files and promotes both to the released version and date.

Stable release path:

- a push to `main` triggers `Publish Module`
- the workflow builds and tests
- `Invoke-NovaRelease` publishes the module
- `Move-UnreleasedChangelog` promotes `CHANGELOG.md` and `RELEASE_NOTE.md` and writes the tag message
- the workflow creates the verified release commit and annotated tag
- the workflow creates a GitHub release whose text is the released `RELEASE_NOTE.md` section

Post-release follow-up:

- the workflow prepares the next prerelease version on `develop`
- release automation commits no longer use `[skip ci]`
- the workflow ignores its own `chore(release): ...` commit on `main` to avoid self-trigger loops

Manual dispatch is available when maintainers need to re-run the publish flow intentionally.

## Public module surface

The public commands currently shipped by the module are:

- `Initialize-KeepAChangelogFile`
- `Test-KeepAChangelogFile`
- `Move-UnreleasedChangelog`
- `Get-KeepAChangelogVersion`
- `Convert-ChangelogReleaseNotesToTagMessage`

End-user usage belongs in the GitHub Pages guide. Keep the `README.md` focused on repository maintenance and release stewardship.

## Documentation, changelog, and follow-up rules

When you change this repository:

- update `README.md` if maintainer workflow, architecture, CI/CD, or tooling expectations changed
- update `docs/index.html` or related site assets if the end-user experience changed
- update `docs/KeepAChangelog/en-US/` if command help changed
- update `CHANGELOG.md` when the change matters to users, maintainers, or future contributors
- update `RELEASE_NOTE.md` when public commands, parameters, or user-facing behavior change

For changelog entries:

- keep the `Keep a Changelog` structure
- write for humans first
- treat `Unreleased` as the source section for the next release

## Security and contribution handling

- use `SECURITY.md` for private vulnerability reporting
- use `CONTRIBUTING.md` for contribution expectations and pull request hygiene
- use `.github/pull_request_template.md` when preparing PR descriptions

## Related project documents

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [SECURITY.md](./SECURITY.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [docs/spec/01-iteration-1-scope.md](./docs/spec/01-iteration-1-scope.md)
- [docs/spec/02-changelog-format-rules.md](./docs/spec/02-changelog-format-rules.md)
- [docs/spec/03-release-workflow.md](./docs/spec/03-release-workflow.md)

[changelog]: https://keepachangelog.com/
[changelog-badge]: https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735
[powershellgallery]: https://www.powershellgallery.com/packages/KeepAChangelog/
[version-badge]: https://img.shields.io/powershellgallery/v/KeepAChangelog?color=blue
