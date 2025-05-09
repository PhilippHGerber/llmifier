import '../models/enums.dart';
import 'configurable_file_group.dart';
import 'sort_by_option.dart';

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

  /// List of glob patterns for files/directories to include globally.
  final List<String> includePatterns;

  /// List of glob patterns for files/directories to exclude globally.
  final List<String> excludePatterns;

  /// Whether verbose output is enabled.
  final bool verbose;

  /// The user-defined or default configuration for file ordering.
  /// The order of groups in this list determines their output priority.
  final List<ConfigurableFileGroup> fileOrderingGroups;

  /// Creates a new, fully resolved [Configuration] instance.
  const Configuration({
    required this.outputPath,
    required this.projectPath,
    required this.projectType,
    required this.mode,
    required this.includePatterns,
    required this.excludePatterns,
    required this.verbose,
    required this.fileOrderingGroups,
  });

  /// Provides the default configuration values.
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
      // Other common file types
      "**analysis_options.yaml",
      "**build.yaml",
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
      // All Hidden Files/Dirs
      ".*",
      "**/.*",
      // Output file itself (will be dynamically added by ConfigLoader)
      "llms*.txt",
      "**/llms*.txt",
    ];

    // --- Define Default File Ordering Groups ---
    // This mimics the spirit of the original v0.0.3 fixed ordering.
    final defaultFileOrderingGroups = [
      ConfigurableFileGroup(
        name: "Documentation",
        patterns: [
          "README.md",
          "CHANGELOG.md",
          "LICENSE",
          "CONTRIBUTING.md",
          "docs/**",
        ],
        order: ["README.md", "CHANGELOG.md", "LICENSE", "CONTRIBUTING.md"],
        sortBy: SortByOption.alphabetical,
      ),
      ConfigurableFileGroup(
        name: "Metadata",
        patterns: ["pubspec.yaml", "analysis_options.yaml", "build.yaml"],
        order: ["pubspec.yaml", "analysis_options.yaml", "build.yaml"],
        sortBy: SortByOption.alphabetical,
      ),
      ConfigurableFileGroup(
        name: "Executable",
        patterns: ["bin/**"],
        sortBy: SortByOption.depthFirst,
      ),
      ConfigurableFileGroup(
        name: "Application Code",
        patterns: ["lib/**"],
        sortBy: SortByOption.depthFirst,
      ),
      ConfigurableFileGroup(
        name: "Packages",
        patterns: ["packages/**"],
        order: ["README.md", "CHANGELOG.md", "pubspec.yaml"],
        sortBy: SortByOption.depthFirst,
      ),
      ConfigurableFileGroup(
        name: "Example",
        patterns: ["example/**"],
        order: ["README.md", "CHANGELOG.md", "pubspec.yaml"],
        sortBy: SortByOption.depthFirst,
      ),
      ConfigurableFileGroup(
        name: "Test",
        patterns: ["test/**"],
        sortBy: SortByOption.depthFirst,
      ),
      ConfigurableFileGroup(
        name: "Other Project Files", // For other top-level config or scripts
        patterns: ["*.yaml", "*.json", "*.toml", "*.sh", "*.bat"],
        sortBy: SortByOption.alphabetical,
      ),
      ConfigurableFileGroup(
        name: "Other (Catch-all)",
        patterns: ["**/*"], // Must be last to catch anything not matched above
        sortBy: SortByOption.alphabetical,
      ),
    ];

    return Configuration(
      outputPath: 'llms.txt',
      projectPath: '.',
      projectType: ProjectType.dart,
      mode: ExtractionMode.full,
      includePatterns: defaultIncludes,
      excludePatterns: defaultExcludes,
      verbose: false,
      fileOrderingGroups: defaultFileOrderingGroups,
    );
  }

  @override
  String toString() {
    final groupsString = fileOrderingGroups
        .map(
          (g) => g.toString(),
        )
        .join(',\n    ');
    return 'Configuration(\n'
        '  outputPath: $outputPath,\n'
        '  projectPath: $projectPath,\n'
        '  projectType: $projectType,\n'
        '  mode: $mode,\n'
        '  includePatterns: $includePatterns,\n'
        '  excludePatterns: $excludePatterns,\n'
        '  verbose: $verbose,\n'
        '  fileOrderingGroups: [\n    $groupsString\n  ]\n'
        ')';
  }
}
