import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../models/file_entry.dart';
import '../models/file_group.dart';

/// Organizes a list of [FileEntry] objects into a specific order based on
/// predefined semantic groups and sorting rules within those groups.
///
/// This aims to produce an output file structure that is logical and potentially
/// easier for LLMs to process.
class FileOrderingStrategy {
  // --- Constants for Group Names ---
  static const String _groupMetadata = 'Metadata';
  static const String _groupDocumentation = 'Documentation';
  static const String _groupApi = 'API';
  static const String _groupExecutable = 'Executable';
  static const String _groupPackages = 'Packages';
  static const String _groupExample = 'Example';
  static const String _groupTest = 'Test';
  static const String _groupOther = 'Other'; // Catch-all for unmatched files

  // --- Fixed order for Documentation files ---
  // Example: ["README.md", "CHANGELOG.md", "LICENSE", "CONTRIBUTING.md", "docs/**.md"]
  static const List<String> _documentationFileOrder = [
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
  ];

  static const List<String> _metaFileOrder = [
    "pubspec.yaml",
    "analysis_options.yaml",
    "build.yaml",
  ];

  // --- Default Priority Groups Definition ---
  // The order in this list defines the output order of the groups.
  static final List<FileGroup> defaultPriorityGroups = [
    // 1. Documentation
    FileGroup(
      name: _groupDocumentation,
      patterns: _documentationFileOrder,
    ),
    // 2. Metadata
    FileGroup(
      name: _groupMetadata,
      patterns: _metaFileOrder,
    ),
    // 3. Executable
    FileGroup(
      name: _groupExecutable,
      patterns: ["bin/**"],
    ),
    // 4. API
    FileGroup(
      name: _groupApi,
      patterns: ["lib/**"],
    ),
    // 5. Packages
    FileGroup(
      name: _groupPackages,
      patterns: ["packages/**"],
    ),
    // 5. Example
    FileGroup(
      name: _groupExample,
      patterns: ["example/**"],
    ),
    // 6. Test
    FileGroup(
      name: _groupTest,
      patterns: ["test/**"],
    ),
    // Note: 'Other' group is handled implicitly if no pattern matches.
  ];

  final List<FileGroup> _priorityGroups;

  /// Creates a [FileOrderingStrategy].
  ///
  /// Optionally accepts a custom list of [priorityGroups]. If null, uses
  /// [defaultPriorityGroups].
  FileOrderingStrategy({List<FileGroup>? priorityGroups}) : _priorityGroups = priorityGroups ?? defaultPriorityGroups;

  /// Organizes the given list of [allFiles] based on the strategy.
  ///
  /// Returns a new list containing the same files but in the prioritized
  /// and sorted order.
  List<FileEntry> organizeFiles(List<FileEntry> allFiles) {
    if (allFiles.isEmpty) {
      return [];
    }

    // 1. Group files
    final Map<String, List<FileEntry>> groupedFiles = {};
    for (final group in _priorityGroups) {
      groupedFiles[group.name] = [];
    }
    groupedFiles[_groupOther] = [];

    for (final fileEntry in allFiles) {
      String? assignedGroupName;
      for (final group in _priorityGroups) {
        if (group.matches(fileEntry.relativePath)) {
          assignedGroupName = group.name;
          break;
        }
      }
      groupedFiles[assignedGroupName ?? _groupOther]!.add(fileEntry);
    }

    // 2. Sort files within each group and concatenate
    final List<FileEntry> sortedFiles = [];
    final List<String> groupOrder = [..._priorityGroups.map((g) => g.name), _groupOther];

    for (final groupName in groupOrder) {
      final filesInGroup = groupedFiles[groupName]!;
      if (filesInGroup.isNotEmpty) {
        _sortGroup(groupName, filesInGroup); // Sort the list in-place
        sortedFiles.addAll(filesInGroup);
      }
    }

    return sortedFiles;
  }

  /// Sorts the [files] list in-place based on the [groupName].
  void _sortGroup(String groupName, List<FileEntry> files) {
    switch (groupName) {
      case _groupMetadata:
        _sortGroupFixedOrder(_metaFileOrder, files);
        break;
      case _groupDocumentation:
        _sortGroupFixedOrder(_documentationFileOrder, files);
        break;
      case _groupApi:
      case _groupExecutable:
      case _groupTest:
        _sortApiLikeGroup(files);
        break;
      case _groupExample:
      case _groupOther:
      default: // Fallback for any unknown group names
        _sortAlphabetically(files);
        break;
    }
  }

  // --- Specific Sorting Logic Implementations ---

  /// Sorts API, Executable, and Test files: by depth (ascending), then alphabetically.
  void _sortApiLikeGroup(List<FileEntry> files) {
    files.sort((a, b) {
      final depthCompare = a.metadata.depth.compareTo(b.metadata.depth);
      if (depthCompare != 0) {
        return depthCompare;
      }
      return compareNatural(a.relativePath, b.relativePath);
    });
  }

  /// Sorts files alphabetically by their relative path.
  void _sortAlphabetically(List<FileEntry> files) {
    files.sort((a, b) => compareNatural(a.relativePath, b.relativePath));
  }

  /// Sorts documentation files according to the predefined `_documentationFileOrder`.
  /// Files not in the predefined list are appended alphabetically.
  void _sortGroupFixedOrder(List<String> fixOrderList, List<FileEntry> files) {
    // Create a map for quick index lookup of the fixed order files
    final Map<String, int> fixedOrderIndex = {for (var i = 0; i < fixOrderList.length; i++) fixOrderList[i]: i};

    files.sort((a, b) {
      final aName = p.basename(a.relativePath);
      final bName = p.basename(b.relativePath);

      final aIndex = fixedOrderIndex[aName];
      final bIndex = fixedOrderIndex[bName];

      if (aIndex != null && bIndex != null) {
        // Both files are in the fixed order list, sort by their index
        return aIndex.compareTo(bIndex);
      } else if (aIndex != null) {
        // Only 'a' is in the fixed order list, it comes first
        return -1;
      } else if (bIndex != null) {
        // Only 'b' is in the fixed order list, it comes first
        return 1;
      } else {
        // Neither file is in the fixed order list, sort them alphabetically
        return compareNatural(a.relativePath, b.relativePath);
      }
    });
  }
}
