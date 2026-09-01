/// Stable namespace for the first persisted PaperClip schema.
///
/// Model declarations live in extensions across their domain files so those
/// files remain independently compilable in focused tests.
enum PaperClipSchemaV1 {}

/// The first schema for the independent mistake library.
///
/// V2 deliberately does not expose the retired `MistakeCard`,
/// `MistakePracticeLayer`, or `ExportRecord` entities.
enum PaperClipSchemaV2 {}

/// Adds grade and semester classification to the independent mistake library.
enum PaperClipSchemaV3 {}

/// Removes the retired PDF/exam and vocabulary-article entities while keeping
/// all active learning data intact.
enum PaperClipSchemaV4 {}
