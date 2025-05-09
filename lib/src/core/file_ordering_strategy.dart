import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../config/configurable_file_group.dart';
import '../config/configuration.dart';
import '../config/sort_by_option.dart';
import '../models/file_entry.dart';

/// Organizes a list of [FileEntry] objects based on user-defined or default
/// [ConfigurableFileGroup] settings from the [Configuration].
class FileOrderingStrategy {
  final List<ConfigurableFileGroup> _fileGroupsConfig;
  final bool _verbose;

  /// Creates a [FileOrderingStrategy].
  ///
  /// Requires the final [Configuration] to access `fileOrderingGroups` and `verbose` settings.
  FileOrderingStrategy(Configuration config)
      : _fileGroupsConfig = config.fileOrderingGroups,
        _verbose = config.verbose;

  /// Organizes the given list of [allFiles] based on the configured strategy.
  ///
  /// Returns a new list containing the same files but in the prioritized
  /// and sorted order.
  List<FileEntry> organizeFiles(List<FileEntry> allFiles) {
    if (allFiles.isEmpty) {
      return [];
    }
    if (_verbose) {
      print(
          'FileOrderingStrategy: Starting to organize ${allFiles.length} files.');
      print('Using ${_fileGroupsConfig.length} configured file groups.');
    }

    final List<FileEntry> finalSortedFiles = [];
    final Set<FileEntry> globallyProcessedFiles = {};

    // 1. Global group assignment (as before)
    final Map<String, List<FileEntry>> filesAssignedToGroup = {};
    for (final groupConfig in _fileGroupsConfig) {
      filesAssignedToGroup[groupConfig.name] = [];
    }

    for (final fileEntry in allFiles) {
      if (globallyProcessedFiles.contains(fileEntry)) continue;
      for (final groupConfig in _fileGroupsConfig) {
        if (groupConfig.matches(fileEntry.relativePath)) {
          filesAssignedToGroup[groupConfig.name]!.add(fileEntry);
          globallyProcessedFiles.add(fileEntry);
          break; // File assigned to this group, move to next file
        }
      }
    }

    // 2. Process each configured group
    for (final groupConfig in _fileGroupsConfig) {
      final filesInThisGroup = filesAssignedToGroup[groupConfig.name] ?? [];
      if (filesInThisGroup.isEmpty) continue;

      if (_verbose) {
        print(
            '\nProcessing group "${groupConfig.name}" with ${filesInThisGroup.length} files.');
      }

      // Process files of this group with the new context-aware logic
      final orderedFilesInGroup =
          _processGroupFilesInContexts(filesInThisGroup, groupConfig);
      finalSortedFiles.addAll(orderedFilesInGroup);
    }

    if (_verbose) {
      print(
          '\nFileOrderingStrategy: Organization complete. Final list has ${finalSortedFiles.length} files.');
      // finalSortedFiles.forEach((f) => print('  - ${f.relativePath}'));
    }
    return finalSortedFiles;
  }

  /// Processes files within a single configured group, aiming to apply 'order'
  /// and 'sortBy' contextually based on directory levels.
  List<FileEntry> _processGroupFilesInContexts(
    List<FileEntry> files,
    ConfigurableFileGroup groupConfig,
  ) {
    if (files.isEmpty) return [];

    // Step 1: Group files by their "primary context path"
    // For `lib/**`: context is `lib`
    // For `README.md`: context is `.` (Root)
    Map<String, List<FileEntry>> filesByContextPath = {};

    for (var file in files) {
      final contextPath = _getContextPathForFile(
        file.relativePath,
        groupConfig,
      );
      filesByContextPath.putIfAbsent(contextPath, () => []).add(file);
    }

    if (_verbose && filesByContextPath.length > 1) {
      print(
          '  Group "${groupConfig.name}": Identified ${filesByContextPath.keys.length} contexts: ${filesByContextPath.keys.join(", ")}');
    }

    // Step 2: Sort the contexts themselves (e.g., alphabetically)
    List<String> sortedContextPaths = filesByContextPath.keys.toList();
    // Here, we might want a more sophisticated way to sort contexts if needed,
    // e.g., if "packages/core" should come before "packages/feature_a".
    // For now, natural string comparison is used.
    sortedContextPaths.sort(compareNatural);

    // Step 3: Process each context
    List<FileEntry> result = [];
    for (var contextPath in sortedContextPaths) {
      List<FileEntry> filesInThisContext = filesByContextPath[contextPath]!;
      if (_verbose && filesByContextPath.length > 1) {
        // Log only if there are multiple contexts for clarity
        print(
            '    Processing context "$contextPath" with ${filesInThisContext.length} files...');
      }

      List<FileEntry> orderedByDirective = [];
      List<FileEntry> remainingInContext = List.from(filesInThisContext);

      // Apply `groupConfig.order` directive *within this context*
      if (groupConfig.order.isNotEmpty) {
        final Set<FileEntry> placedByOrder = {};

        // Iterate through the 'order' list defined in the group configuration
        for (final orderedBaseName in groupConfig.order) {
          // Find files in the current context that match this basename
          List<FileEntry> matchingFilesInContextForOrder = [];
          for (final entry in remainingInContext) {
            // This condition checks if the file's basename matches AND
            // if the file's path starts with the current contextPath.
            // This is a heuristic to apply 'order' somewhat locally.
            // A more precise rule might be needed if 'order' should only apply
            // to files *directly* under contextPath, not in sub-subdirectories.
            if (p.basename(entry.relativePath) == orderedBaseName &&
                entry.relativePath.startsWith(contextPath) &&
                !placedByOrder.contains(entry)) {
              // Ensure not already placed by a previous rule in group.order
              matchingFilesInContextForOrder.add(entry);
            }
          }

          // If multiple files match the basename (e.g. multiple README.md in different subdirs of the context),
          // sort them by path to ensure deterministic order before adding.
          matchingFilesInContextForOrder.sort(
            (a, b) => compareNatural(a.relativePath, b.relativePath),
          );

          for (final entryToAdd in matchingFilesInContextForOrder) {
            if (!placedByOrder.contains(entryToAdd)) {
              // Double check to avoid duplicates if logic changes
              orderedByDirective.add(entryToAdd);
              placedByOrder.add(entryToAdd);
            }
          }
        }
        remainingInContext.removeWhere(
          (entry) => placedByOrder.contains(entry),
        );

        if (_verbose && orderedByDirective.isNotEmpty) {
          print(
              '      Context "$contextPath": Applied fixed order for ${orderedByDirective.length} files.');
        }
      }

      // Sort the remaining files in the context using `groupConfig.sortBy`
      _sortListOfFiles(remainingInContext, groupConfig.sortBy);
      if (_verbose && remainingInContext.isNotEmpty) {
        print(
            '      Context "$contextPath": Sorted remaining ${remainingInContext.length} files by ${groupConfig.sortBy.name}.');
      }

      result.addAll(orderedByDirective);
      result.addAll(remainingInContext);
    }
    return result;
  }

  /// Determines the "context path" for a file relative to a group's patterns.
  /// This is a critical heuristic and may need refinement.
  /// The goal is to identify the main subdirectory or scope a file belongs to
  /// within a broader group pattern (e.g., "packages/my_package" from "packages/**").
  String _getContextPathForFile(
    String relativePath,
    ConfigurableFileGroup groupCfg,
  ) {
    List<String> pathSegments = p.url.split(relativePath);

    // Try to find the most specific directory part based on group patterns.
    // This is a simplification. A more robust solution might involve
    // finding the longest non-glob prefix of a matching pattern.
    for (String patternStr in groupCfg.patterns) {
      if (patternStr.endsWith('/**')) {
        String basePatternDir = patternStr.substring(
          0,
          patternStr.length - 3,
        );
        if (relativePath.startsWith(basePatternDir)) {
          if (basePatternDir == "." || basePatternDir.isEmpty) {
            // e.g. pattern "/**"
            return pathSegments.isNotEmpty ? pathSegments.first : ".";
          }
          List<String> basePatternParts = p.url.split(basePatternDir);

          if (pathSegments.length > basePatternParts.length) {
            return p.url.joinAll(
              pathSegments.sublist(0, basePatternParts.length + 1),
            );
          } else if (pathSegments.length == basePatternParts.length &&
              pathSegments.join('/') == basePatternParts.join('/')) {
            // File is directly in the basePatternDir, e.g. pattern "lib/**" and file "lib/app.dart" (context "lib")
            return basePatternDir;
          }
        }
      } else if (!patternStr.contains('*')) {
        // Exact file pattern
        if (patternStr == relativePath) {
          String dirname = p.url.dirname(relativePath);
          return dirname == "." ? "." : dirname; // Return "." for root files
        }
      }
      // Other pattern types (e.g., "lib/*.dart") would need more specific logic
      // to determine their "context". For now, they'll use the fallback.
    }

    // Fallback heuristic:
    // For paths like "a/b/c.dart", if the group is broad (e.g. "**/*"),
    // we might consider "a" or "a/b" as context.
    // If the first segment matches a common top-level dir from patterns (e.g. "packages", "examples", "lib")
    // and there's a subdirectory, that subdirectory becomes the context.
    if (pathSegments.length > 1) {
      String firstSegment = pathSegments.first;
      bool isKnownTopLevelPattern =
          groupCfg.patterns.any((pat) => pat.startsWith("$firstSegment/**"));
      if (isKnownTopLevelPattern) {
        return p.url.join(
          pathSegments[0],
          pathSegments[1],
        );
      }
      // If not a known top-level pattern, the context might be just the first directory.
      // Or, for files directly in root matched by a root-level pattern like "*.yaml", context is "."
      if (p.url.dirname(relativePath) == ".") return ".";
      return firstSegment;
    }
    return "."; // Default to root context
  }

  /// Sorts a given list of [FileEntry]s based on the [SortByOption].
  void _sortListOfFiles(List<FileEntry> files, SortByOption sortBy) {
    if (files.isEmpty) return;

    switch (sortBy) {
      case SortByOption.alphabetical:
        files.sort((a, b) => compareNatural(a.relativePath, b.relativePath));
        break;
      case SortByOption.depthFirst:
        files.sort((a, b) {
          // Using global depth, which usually works well.
          // For true relative depth-sorting within a context, metadata.depth
          // would need to be recalculated or adjusted based on the contextPath.
          final depthCompare = a.metadata.depth.compareTo(b.metadata.depth);
          if (depthCompare != 0) {
            return depthCompare;
          }
          return compareNatural(a.relativePath, b.relativePath);
        });
        break;
    }
  }
}
