/// Defines the recognized types of projects llmifier can handle.
///
/// This influences default file ordering and potentially processing logic.
enum ProjectType {
  /// A standard Dart/Flutter project (e.g., library, CLI tool, app).
  dart,
}

/// Defines the different modes for extracting content.
enum ExtractionMode {
  /// Extracts the full content of the files. Suitable for reviews or development.
  full,

  /// Extracts only the public API surface with documentation comments. Suitable for package usage context.
  api,
}
