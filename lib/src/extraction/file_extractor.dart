import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

// Local imports
import '../config/configuration.dart';
import '../models/file_entry.dart';
import '../models/file_metadata.dart';

/// Extracts relevant files from the project directory based on the configuration.
class FileExtractor {
  final Configuration _config;
  final List<Glob> _includeGlobs;
  final List<Glob> _excludeGlobs;

  /// Creates a [FileExtractor] instance.
  ///
  /// Requires the final [Configuration] object.
  /// Pre-compiles the glob patterns for efficiency.
  FileExtractor(this._config)
      : _includeGlobs = _config.includePatterns.map((p) => Glob(p)).toList(),
        _excludeGlobs = _config.excludePatterns.map((p) => Glob(p)).toList() {
    if (_config.verbose) {
      print('FileExtractor initialized.');
      print('Include patterns: ${_config.includePatterns}');
      print('Exclude patterns: ${_config.excludePatterns}');
    }
  }

  /// Extracts all files matching the include/exclude criteria.
  ///
  /// Returns a list of [FileEntry] objects, each including calculated [FileMetadata].
  /// The list is not sorted according to the final ordering strategy at this stage.
  List<FileEntry> extractFiles() {
    final List<FileEntry> extractedFiles = [];
    final projectDir = Directory(_config.projectPath);

    if (!projectDir.existsSync()) {
      stderr.writeln('Error: Project directory not found: ${_config.projectPath}');
      return [];
    }

    if (_config.verbose) {
      print('Starting file extraction from: ${projectDir.absolute.path}');
    }

    // Start recursive processing
    _processDirectory(projectDir, extractedFiles);

    if (_config.verbose) {
      print('File extraction completed. Found ${extractedFiles.length} files.');
    }

    // Sorting happens later in ProjectProcessor using FileOrderingStrategy
    return extractedFiles;
  }

  /// Recursively processes a directory and its contents.
  void _processDirectory(Directory currentDir, List<FileEntry> results) {
    final String currentDirPathAbsolute = path.normalize(currentDir.absolute.path);
    final String projectRootPathAbsolute = path.normalize(Directory(_config.projectPath).absolute.path);

    if (_config.verbose) {
      final String relativePathForLog = path.relative(currentDirPathAbsolute, from: projectRootPathAbsolute);
      print('Processing directory: ${relativePathForLog.isEmpty ? "." : relativePathForLog}');
    }

    try {
      final List<FileSystemEntity> entities = currentDir.listSync(followLinks: false);

      // Sort entities for deterministic order (optional but good practice)
      // Directories first - then alphabetical
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return path.basename(a.path).compareTo(path.basename(b.path));
      });

      for (final entity in entities) {
        final String entityPathAbsolute = path.normalize(entity.absolute.path);
        final String baseName = path.basename(entityPathAbsolute);

        // 1. Skip hidden files/directories (starting with '.')
        // Added check to prevent infinite loops on links like .git/logs/refs -> ../../logs/refs
        if (baseName.startsWith('.') || entity is Link) {
          if (_config.verbose) {
            if (baseName.startsWith('.')) print('  Skipping hidden entry: $baseName');
            if (entity is Link) print('  Skipping link: $baseName');
          }
          continue;
        }

        // Calculate relative path using forward slashes for matching
        final String relativePath = path
            .relative(entityPathAbsolute, from: projectRootPathAbsolute)
            .replaceAll('\\', '/'); // Ensure forward slashes

        // 2. Check exclusion patterns
        if (_shouldExclude(relativePath, entity is Directory)) {
          if (_config.verbose) {
            print('  Skipping excluded ${entity is Directory ? "directory" : "file"}: $relativePath');
          }
          continue;
        }

        // 3. Process based on type (Directory or File)
        if (entity is Directory) {
          // Recurse into subdirectories
          _processDirectory(entity, results);
        } else if (entity is File) {
          // 4. Check inclusion patterns for files
          if (_shouldInclude(relativePath)) {
            // File matches, add it with metadata
            _addFile(entity, relativePath, results);
          } else {
            if (_config.verbose) {
              print('  Skipping file (does not match include patterns): $relativePath');
            }
          }
        }
      }
    } on FileSystemException catch (e) {
      stderr.writeln("Warning: Could not list directory ${currentDir.path}: $e");
    }
  }

  /// Adds a file to the results list after reading its content and calculating metadata.
  /// Expects relativePath to potentially start with './'.
  void _addFile(File file, String relativePath, List<FileEntry> results) {
    try {
      final String content = file.readAsStringSync();
      // Metadata calculation should handle './' correctly
      final FileMetadata metadata = FileMetadata.fromRelativePath(relativePath);

      results.add(FileEntry(
        relativePath: relativePath,
        content: content,
        metadata: metadata,
      ));

      if (_config.verbose) {
        print('  Added file: $relativePath (Metadata: $metadata)');
      }
    } on FileSystemException catch (e) {
      stderr.writeln("Warning: Could not read file ${file.path}: $e");
    } catch (e) {
      stderr.writeln("Warning: Error processing file ${file.path}: $e");
    }
  }

  /// Checks if a given relative path should be excluded based on exclude globs.
  bool _shouldExclude(String relativePath, bool isDirectory) {
    // Check if any exclude glob matches the relative path.
    // Globs can match files or directories.
    return _excludeGlobs.any((glob) => glob.matches(relativePath));
  }

  /// Checks if a given relative path should be included based on include globs.
  /// Assumes _shouldExclude was already checked and returned false.
  bool _shouldInclude(String relativePath) {
    // If no include patterns are defined, include everything (that wasn't excluded).
    if (_includeGlobs.isEmpty) {
      return true;
    }
    // Otherwise, it must match at least one include pattern.
    // return _includeGlobs.any((glob) => glob.matches(relativePath));
    // Set breakpoint inside this lambda, on the 'glob.matches' call:
    return _includeGlobs.any((glob) {
      bool matches = glob.matches(relativePath); // <--- BREAKPOINT HERE
      // You can also inspect 'glob.pattern' here
      return matches;
    });
  }
}
