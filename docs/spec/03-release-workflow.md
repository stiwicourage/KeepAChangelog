# 03. Release workflow

## Release algorithm

When a release is published from `CHANGELOG.md`, the workflow must:

1. Read the current `## [Unreleased]` section.
2. Extract the current `[Unreleased]` compare-link prefix and previous release reference.
3. Build release notes by removing empty `###` subsections.
4. Insert `## [<version>] - <date>` directly below `## [Unreleased]`.
5. Clear the `Unreleased` body while keeping subsection headings.
6. Update `[Unreleased]` so it compares `<new tag>...HEAD`.
7. Add or update `[<version>]` so it compares `<previous ref>...<new tag>`.

If there is no previous release reference yet, the first release should:

- create `[Unreleased]` from `<new tag>...HEAD`
- create `[<version>]` as a release tag URL instead of a compare URL

## Expected outputs

The release workflow should expose or compute these values:

- `Release.Version`
- `Release.Date`
- `Release.Tag`
- `UnreleasedCompareLinkPrefix`
- `PreviousReleaseReference`
- `UnreleasedBody`
- `ReleaseNotesBody`
- `ClearedUnreleasedBody`
- `NewReleaseSection`
- `UpdatedUnreleasedLink`
- `NewReleaseCompareLink`
- `NewReleaseLink`
- `TagMessageText`

The public command should accept `-Version` and optional `-Date`, then derive `Release.Tag` from `Version`.

## Tag-message rules

`Convert-ChangelogReleaseNotesToTagMessage` must:

1. Turn markdown headings into plain section titles.
2. Turn markdown bullets into plain lines.
3. Collapse repeated blank lines.
4. Trim the final result.
