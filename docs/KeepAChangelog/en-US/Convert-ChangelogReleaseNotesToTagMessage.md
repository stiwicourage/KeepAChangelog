---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 04/30/2026
PlatyPS schema version: 2024-05-01
title: Convert-ChangelogReleaseNotesToTagMessage
---

# Convert-ChangelogReleaseNotesToTagMessage

## SYNOPSIS

Converts markdown release notes to plain text.

## SYNTAX

### __AllParameterSets

```text
PS> Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes <string> [<CommonParameters>]
```

## DESCRIPTION

`Convert-ChangelogReleaseNotesToTagMessage` simplifies markdown release notes for tag messages.

The command:

- turns `###` headings into plain section names
- turns markdown bullets into plain lines
- collapses repeated blank lines
- trims the final result

## EXAMPLES

### EXAMPLE 1

```text
PS> Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes "### Fixed`n`n- Fixed CLI parsing."
```

Returns:

```text
Fixed

Fixed CLI parsing.
```

## PARAMETERS

### -ReleaseNotes

Markdown release-notes text to convert.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable.
