import 'dart:io';

import 'package:yaml/yaml.dart';

// Local imports
import '../config/configuration.dart';
import '../core/file_ordering_strategy.dart';
import '../models/file_entry.dart';
import '../models/project_context.dart';
import 'content_processor.dart';
import 'dart_content_processor.dart';

/// Processes the raw list of file entries based on the configuration.
///
/// This involves:
/// - Processing file content using appropriate [ContentProcessor]s.
/// - Extracting project metadata (e.g., package name, version from pubspec.yaml).
/// - Sorting the files using [FileOrderingStrategy].
/// - Returning a [ProjectContext] containing processed and sorted files and metadata.
class ProjectProcessor {
  final Configuration _config;
  final ContentProcessor _dartProcessor;
  final FileOrderingStrategy _orderingStrategy;

  // Add other processors here if needed for other file types later

  /// Creates a [ProjectProcessor].
  ///
  /// Requires the final [Configuration]. Initializes content processors and
  /// the file ordering strategy.
  ProjectProcessor(this._config)
      : _dartProcessor = DartContentProcessor(),
        _orderingStrategy = FileOrderingStrategy(_config) {
    // <-- Initialize strategy
    // Initialize other processors if necessary
    if (_config.verbose) {
      print('ProjectProcessor initialized.');
    }
  }

  /// Processes the raw file list, extracts metadata, and sorts the files.
  ///
  /// - [rawFiles]: The list of [FileEntry] objects directly from [FileExtractor].
  ///
  /// Returns a [ProjectContext] with processed and sorted data.
  ProjectContext process(List<FileEntry> rawFiles) {
    if (_config.verbose) {
      print('Starting project processing...');
      print('Received ${rawFiles.length} raw files from extractor.');
    }

    // 1. Process file content and collect processed entries
    final List<FileEntry> processedFiles = [];
    String? packageName;
    String? packageVersion;
    FileEntry? pubspecEntry;

    for (final entry in rawFiles) {
      if (entry.relativePath == 'pubspec.yaml') {
        pubspecEntry = entry;
        // Extract info later, but add the file to processed list now
        // Assuming pubspec content doesn't need 'processing' via ContentProcessor
        processedFiles.add(entry);
        continue;
      }
      // Process other files using the appropriate content processor
      processedFiles.add(_processSingleFile(entry));
    }

    // 2. Extract metadata from pubspec.yaml if found
    if (pubspecEntry != null) {
      final pubspecInfo = _extractPubspecInfo(pubspecEntry);
      packageName = pubspecInfo['name'];
      packageVersion = pubspecInfo['version'];
      if (_config.verbose) {
        print(
            'Extracted from pubspec.yaml: name=$packageName, version=$packageVersion');
      }
    } else if (_config.verbose) {
      print('pubspec.yaml not found in extracted files.');
    }

    // 3. Sort the processed files using the ordering strategy <-- NEW STEP
    if (_config.verbose) {
      print(
          'Applying file ordering strategy to ${processedFiles.length} processed files...');
    }
    final List<FileEntry> sortedFiles =
        _orderingStrategy.organizeFiles(processedFiles);
    if (_config.verbose) {
      print(
          'File ordering completed. Resulting order has ${sortedFiles.length} files.');
      // Optional: Print the sorted file names for debugging
      // sortedFiles.forEach((f) => print('  - ${f.relativePath}'));
    }

    if (_config.verbose) {
      print('Project processing finished.');
    }

    // 4. Create and return the context with the sorted files <-- UPDATED STEP
    return ProjectContext(
      type: _config.projectType,
      packageName: packageName,
      packageVersion: packageVersion,
      files: sortedFiles, // <-- Use the sorted list here
      extractionTime: DateTime.now(), // Record the time processing finished
    );
  }

  /// Processes the content of a single file entry based on its type and config mode.
  /// Preserves the original metadata.
  FileEntry _processSingleFile(FileEntry entry) {
    // Determine if it's a Dart file
    if (entry.relativePath.endsWith('.dart')) {
      if (_config.verbose) {
        print(
            '  Processing Dart file content: ${entry.relativePath} (Mode: ${_config.mode.name})');
      }
      final processedContent = _dartProcessor.processContent(
        entry.relativePath,
        entry.content,
        _config.mode,
      );
      // Return a new entry with processed content if it changed,
      // making sure to pass the original metadata.
      if (processedContent != entry.content) {
        return FileEntry(
          relativePath: entry.relativePath,
          content: processedContent,
          metadata: entry.metadata,
        );
      }
    }
    // For non-Dart files or if content didn't change, return the original entry
    return entry;
  }

  /// Extracts package name and version from pubspec.yaml content.
  Map<String, String?> _extractPubspecInfo(FileEntry pubspecEntry) {
    String? name;
    String? version;
    try {
      final yamlContent = loadYaml(pubspecEntry.content);
      if (yamlContent is YamlMap) {
        final nameNode = yamlContent['name'];
        final versionNode = yamlContent['version'];
        if (nameNode is String) {
          name = nameNode;
        }
        if (versionNode is String) {
          version = versionNode;
        } else if (versionNode is num) {
          // Handle case where version might be a number (less common)
          version = versionNode.toString();
        }
      }
    } catch (e) {
      // Handle potential YAML parsing errors
      stderr.writeln("Warning: Could not parse pubspec.yaml: $e");
    }
    return {'name': name, 'version': version};
  }
}
