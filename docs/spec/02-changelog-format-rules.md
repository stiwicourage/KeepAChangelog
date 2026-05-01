# 02. Changelog format rules

## Required structure

Every managed changelog must contain:

1. A top-level `## [Unreleased]` section.
2. A footer reference link for `[Unreleased]`.
3. Versioned release headings in the form `## [<version>] - <date>`.

## Required compare link

After the first release, the footer must include:

```markdown
[Unreleased]: https://github.com/<owner>/<repo>/compare/<previous>...HEAD
```

When the compare link exists, the module extracts:

- The compare-link prefix up to `/compare/`
- The previous release reference between `/compare/` and `...HEAD`

## Release object contract

Release promotion requires a hashtable with all three values:

```powershell
$Release = @{
    Version = '1.6.0'
    Date    = '2026-04-30'
    Tag     = '1.6.0'
}
```

If `Version`, `Date`, or `Tag` is missing or empty, the release command must fail.

For a first release without an existing footer compare link, the release command needs a repository URL so it can add the initial footer links.

## Section handling rules

1. Unreleased content is moved, not copied.
2. Empty `###` subsections stay in `Unreleased`.
3. Empty `###` subsections are removed from the new release notes.
4. Simple changelog text without `###` subsections is preserved as-is.
