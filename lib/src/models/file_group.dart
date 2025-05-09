import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

/// Represents a semantic group of files defined by a name and glob patterns.
///
/// Used by [FileOrderingStrategy] to categorize files before sorting.
@immutable
class FileGroup {
  /// The unique identifier name for the group (e.g., "Metadata", "API").
  final String name;

  /// The list of glob patterns associated with this group.
  final List<String> patterns;

  // Cache compiled globs for efficiency
  late final List<Glob> _compiledGlobs = patterns.map((p) => Glob(p)).toList();

  /// Creates a definition for a file group.
  FileGroup({required this.name, required this.patterns}) {
    // Basic validation: Ensure name is not empty
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Group name cannot be empty.');
    }
  }

  /// Checks if the given [relativePath] matches any of the glob patterns
  /// defined for this group.
  ///
  /// Expects [relativePath] to use forward slashes ('/').
  bool matches(String relativePath) {
    // Handle potential edge case of empty path? For now, assume valid paths.
    if (relativePath.isEmpty) return false;
    return _compiledGlobs.any((glob) => glob.matches(relativePath));
  }

  @override
  String toString() {
    return 'FileGroup(name: "$name", patterns: $patterns)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileGroup && //
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
