# SwiftData legacy fixture

`PaperClipLegacyUnversionedStore.tar.gz.base64` is a static, unversioned
SwiftData store containing one record for every persisted V1 model.

The fixture was generated from repository revision
`522df115fe4b78e06509c65d98763ad135151b2e`, before the versioned schema was
introduced. `PaperClipLegacyStoreFixtureBuilder.swift` was compiled against an
archive of that revision, so the fixture uses the original top-level model
types rather than the current versioned namespace.

Ordinary tests must only decode and open this fixture. Do not regenerate it as
part of a test run. Regeneration is an explicit compatibility-baseline change
that requires migration review and an updated SHA-256 file.
