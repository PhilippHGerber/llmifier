// Local imports
import 'enums.dart'; // For ProjectType
import 'file_entry.dart'; // For the list of files

/// Represents the overall context of the processed project.
///
/// This includes metadata about the project (like name and version) and
/// the list of file entries with their processed content.
class ProjectContext {
  /// The determined type of the project.
  final ProjectType type;

  /// The name of the package, extracted from pubspec.yaml (if found).
  final String? packageName;

  /// The version of the package, extracted from pubspec.yaml (if found).
  final String? packageVersion;

  /// The list of file entries after content processing.
  final List<FileEntry> files;

  /// The time when the extraction and processing occurred.
  final DateTime extractionTime;

  /// Creates a new [ProjectContext].
  const ProjectContext({
    required this.type,
    this.packageName,
    this.packageVersion,
    required this.files,
    required this.extractionTime,
  });

  @override
  String toString() {
    return 'ProjectContext(type: $type, packageName: $packageName, '
        'packageVersion: $packageVersion, fileCount: ${files.length}, '
        'extractionTime: $extractionTime)';
  }
}
