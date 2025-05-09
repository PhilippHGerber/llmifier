import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import 'sort_by_option.dart';

/// Represents a user-configurable group of files for ordering purposes.
///
/// Instances of this class are typically created by parsing the
/// `fileOrdering.groups` section of the `llmifierrc.yaml` configuration file.
@immutable
class ConfigurableFileGroup {
  /// The display name of the group (e.g., "Documentation", "API").
  /// Used primarily for logging and debugging.
  final String name;

  /// A list of glob patterns that define which files belong to this group.
  /// A file is considered part of this group if it matches any of these patterns.
  final List<String> patterns;

  /// An optional list of specific file basenames (e.g., "README.md", "pubspec.yaml")
  /// that should appear at the beginning of this group, in the specified order.
  /// Files matched by `order` are processed before other files in this group
  /// that are sorted by `sortBy`.
  final List<String> order;

  /// The strategy to use for sorting files within this group, after
  /// files specified in `order` have been placed.
  final SortByOption sortBy;

  // Cache compiled globs for efficiency
  late final List<Glob> _compiledGlobs = patterns.map((p) => Glob(p)).toList();

  /// Creates a new [ConfigurableFileGroup].
  ///
  /// - [name]: Must not be empty.
  /// - [patterns]: Must not be empty.
  /// - [order]: Defaults to an empty list if not provided.
  /// - [sortBy]: Defaults to [SortByOption.alphabetical] if not provided.
  ConfigurableFileGroup({
    required this.name,
    required this.patterns,
    this.order = const [], // Default to empty list
    this.sortBy = SortByOption.alphabetical, // Default sort option
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Group name cannot be empty.');
    }
    if (patterns.isEmpty) {
      throw ArgumentError.value(
        patterns,
        'patterns',
        'Group patterns list cannot be empty.',
      );
    }
  }

  /// Checks if the given [relativePath] matches any of the glob patterns
  /// defined for this group.
  ///
  /// Expects [relativePath] to use forward slashes ('/').
  bool matches(String relativePath) {
    if (relativePath.isEmpty) return false;
    return _compiledGlobs.any((glob) => glob.matches(relativePath));
  }

  @override
  String toString() {
    return 'ConfigurableFileGroup(name: "$name", patterns: $patterns, order: $order, sortBy: $sortBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConfigurableFileGroup) return false;
    // For simplicity in this context, comparing by name might be enough
    // if names are expected to be unique. Or compare all fields for full equality.
    return runtimeType == other.runtimeType &&
        name == other.name &&
        // Using simple list equality for patterns and order for this example
        _listEquals(patterns, other.patterns) &&
        _listEquals(order, other.order) &&
        sortBy == other.sortBy;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      patterns.fold(0, (prev, curr) => prev ^ curr.hashCode) ^
      order.fold(0, (prev, curr) => prev ^ curr.hashCode) ^
      sortBy.hashCode;

  /// Helper for list equality.
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
