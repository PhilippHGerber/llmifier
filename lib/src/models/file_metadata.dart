import 'package:path/path.dart' as path;

/// Represents metadata associated with a file, primarily used for sorting.
///
/// This information is collected by the [FileExtractor] and used by the
/// [FileOrderingStrategy] to determine the correct order of files in the output.
class FileMetadata {
  /// The directory depth of the file relative to the project root.
  /// A file directly in the root has a depth of 0.
  /// `lib/src/file.dart` has a depth of 2.
  final int depth;

  /// The file extension, including the leading dot (e.g., ".dart", ".md").
  /// Returns an empty string if the file has no extension.
  final String extension;

  /// Creates metadata for a file.
  const FileMetadata({
    required this.depth,
    required this.extension,
  });

  /// Creates [FileMetadata] by calculating values from a relative path.
  ///
  /// Expects the [relativePath] to use forward slashes ('/') as separators.
  factory FileMetadata.fromRelativePath(String relativePath) {
    // Calculate depth
    final parts = path.split(relativePath.replaceAll('\\', '/'));
    // If the path only contains the filename (no slashes), parts length is 1, depth is 0.
    // If path is 'lib/file.dart', parts is ['lib', 'file.dart'], length 2, depth 1.
    // The depth is the number of directory components.
    final depth = parts.length > 1 ? parts.length - 1 : 0;

    // Calculate extension
    final extension = path.extension(relativePath);

    return FileMetadata(depth: depth, extension: extension);
  }

  @override
  String toString() {
    return 'FileMetadata(depth: $depth, extension: "$extension")';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileMetadata && runtimeType == other.runtimeType && depth == other.depth && extension == other.extension;

  @override
  int get hashCode => depth.hashCode ^ extension.hashCode;
}
