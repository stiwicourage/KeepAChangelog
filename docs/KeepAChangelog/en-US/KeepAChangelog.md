---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: ''
Locale: en-US
Module Guid: 58cf9260-13f2-4eb0-91f2-80b1a0c41f31
Module Name: KeepAChangelog
ms.date: 04/30/2026
PlatyPS schema version: 2024-05-01
title: KeepAChangelog Module
---

# KeepAChangelog Module

## Description

KeepAChangelog helps you create, validate, and release changelog files that follow the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

Use the module when you want a repeatable PowerShell workflow for:

- creating a changelog template with `## [Unreleased]`
- validating required compare links and release headings
- promoting unreleased notes into a versioned release section
- generating plain-text tag messages from markdown release notes

## KeepAChangelog Cmdlets

### `PS> New-KeepAChangelogFile`

Creates a changelog template with standard Keep a Changelog headings and the required `[Unreleased]` compare link.

### `PS> Test-KeepAChangelogFile`

Validates that a changelog contains the required `## [Unreleased]` section, reference links, and release-heading format.

### `PS> Publish-KeepAChangelogRelease`

Moves the current `Unreleased` content into a versioned release section and updates compare links.

### `PS> Convert-ChangelogReleaseNotesToTagMessage`

Converts markdown release notes into a trimmed plain-text tag message.
