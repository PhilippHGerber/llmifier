import '../models/enums.dart';

/// Defines the interface for processing the content of a file
/// based on the configured extraction mode.
///
/// Implementations of this interface can modify file content, for example,
/// by removing private members and implementation details for the 'api' mode,
/// or performing other transformations.
abstract class ContentProcessor {
  /// Processes the given [content] of a file at [relativePath].
  ///
  /// The processing logic depends on the specified [mode].
  ///
  /// - [relativePath]: The path of the file relative to the project root.
  ///   This can be useful for context or error reporting.
  /// - [content]: The original string content of the file.
  /// - [mode]: The [ExtractionMode] (e.g., full, api) dictating how the
  ///   content should be processed.
  ///
  /// Returns the processed string content.
  String processContent(
    String relativePath,
    String content,
    ExtractionMode mode,
  );
}
