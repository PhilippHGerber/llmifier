// lib/src/config/configuration.dart

import '../models/enums.dart';

/// Represents the fully resolved configuration for the llmifier tool.
///
/// This object merges defaults, configuration file settings, and CLI arguments
/// into the final settings used for processing.
class Configuration {
  /// The final path for the output file.
  final String outputPath;

  /// The final path to the project directory.
  final String projectPath;

  /// The determined project type.
  final ProjectType projectType;

  /// The determined extraction mode.
  final ExtractionMode mode;

  /// List of glob patterns for files/directories to include.
  final List<String> includePatterns;

  /// List of glob patterns for files/directories to exclude.
  final List<String> excludePatterns;

  /// Whether verbose output is enabled.
  final bool verbose;

  /// Creates a new, fully resolved [Configuration] instance.
  const Configuration({
    required this.outputPath,
    required this.projectPath,
    required this.projectType,
    required this.mode,
    required this.includePatterns,
    required this.excludePatterns,
    required this.verbose,
  });

  /// Provides the default configuration values using effective glob patterns.
  factory Configuration.defaults() {
    // --- Define the effective default patterns based on testing ---
    final defaultIncludes = [
      // Specific file names (Root + Nested)
      "**README.md",
      "**CHANGELOG.md",
      "**LICENSE",
      "**CONTRIBUTING.md",
      "**pubspec.yaml",
      // Files within specific directories (Root + Nested)
      "**lib/**.dart",
      "**bin/**.dart",
      "**test/**.dart",
      "**example/**.dart",
    ];

    final defaultExcludes = [
      // Specific Generated File Types (Root + Nested) -> Requires two patterns
      "*.g.dart", // Root
      "**/*.g.dart", // Nested
      "*.freezed.dart", // Root
      "**/*.freezed.dart", // Nested

      // Directories (Root + Nested) - Use **<dirname> (without trailing slash)
      "**build",
      "**.dart_tool",
      "**.git",
      "**.github",
      "**.idea",
      "**.vscode",
      "**node_modules",
      "**ios",
      "**android",
      "**web",
      "**macos",
      "**linux",
      "**windows",

      // All Hidden Files/Dirs (Root + Nested) -> Requires two patterns
      ".*", // Root hidden files/dirs
      "**/.*", // Nested hidden files/dirs

      // Output file itself (Root + Nested) - Use filename and **/filename
      // The actual name 'llms.txt' is the default outputPath below
      "llms*.txt", // Root (Matches the default outputPath)
      "**/llms*.txt", // Nested
    ];

    return Configuration(
      outputPath: 'llms.txt', // Default output file name
      projectPath: '.', // Default project path (current directory)
      projectType: ProjectType.dart, // Default project type
      mode: ExtractionMode.full, // Default mode
      // Use the effective patterns defined above
      includePatterns: defaultIncludes,
      excludePatterns: defaultExcludes,
      verbose: false, // Default verbosity
    );
  }

  @override
  String toString() {
    // Useful for debugging
    return 'Configuration(outputPath: $outputPath, projectPath: $projectPath, '
        'projectType: $projectType, mode: $mode, '
        'includePatterns: $includePatterns, excludePatterns: $excludePatterns, '
        'verbose: $verbose)';
  }
}
