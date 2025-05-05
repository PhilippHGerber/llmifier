import 'file_metadata.dart';

/// Represents a single file extracted from the project.
class FileEntry {
  /// The path of the file relative to the project root.
  /// Uses forward slashes ('/') as separators.
  final String relativePath;

  /// The content of the file as a string.
  final String content;

  /// Metadata associated with the file (e.g., depth, extension).
  final FileMetadata metadata; // Added field

  /// Creates a new [FileEntry].
  const FileEntry({
    required this.relativePath,
    required this.content,
    required this.metadata,
  });

  @override
  String toString() {
    // Simple representation for debugging
    return 'FileEntry(relativePath: "$relativePath", content: ${content.length} chars, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileEntry &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          metadata == other.metadata;

  @override
  int get hashCode => relativePath.hashCode ^ metadata.hashCode;
}
