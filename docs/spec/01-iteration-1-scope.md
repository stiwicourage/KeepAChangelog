# 01. Iteration 1 scope

## Purpose

The first iteration establishes the PowerShell foundation for Keep a Changelog automation in this repository.

## Deliverables

1. A PowerShell module that can create a changelog template.
2. A validation command that checks the required Keep a Changelog structure.
3. A release command that promotes `## [Unreleased]` content into a versioned release section.
4. Plain-text tag-message generation from markdown release notes.

## Public commands

- `Initialize-KeepAChangelogFile`
- `Test-KeepAChangelogFile`
- `Publish-KeepAChangelogRelease`
- `Convert-ChangelogReleaseNotesToTagMessage`

## Non-goals for iteration 1

- Automatic Git tagging
- Automatic release publishing
- CLI wrapper commands outside the PowerShell module
