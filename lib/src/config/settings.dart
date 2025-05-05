/// Represents the raw settings parsed directly from command-line arguments.
///
/// This class holds the values provided by the user via the CLI, before
/// defaults or configuration file values are merged.
class Settings {
  /// Path to the output file specified via CLI. Null if not specified.
  final String? outputPath;

  /// Path to the project directory specified via CLI. Null if not specified.
  final String? projectPath;

  /// Project type specified via CLI (e.g., "dart", "flutter"). Null if not specified.
  final String? projectType;

  /// Extraction mode specified via CLI (e.g., "full", "api"). Null if not specified.
  final String? mode;

  /// List of include patterns specified via CLI. Empty list if none specified.
  final List<String> includePatterns;

  /// List of exclude patterns specified via CLI. Empty list if none specified.
  final List<String> excludePatterns;

  /// Whether verbose output was requested via CLI.
  final bool? verbose;

  /// Whether config file initialization was requested via CLI.
  final bool initConfig;

  /// Whether help was requested via CLI.
  final bool showHelp;

  /// Creates a new instance of [Settings].
  const Settings({
    this.outputPath,
    this.projectPath,
    this.projectType,
    this.mode,
    required this.includePatterns,
    required this.excludePatterns,
    this.verbose,
    required this.initConfig,
    required this.showHelp,
  });

  @override
  String toString() {
    // Useful for debugging
    return 'Settings(outputPath: $outputPath, projectPath: $projectPath, '
        'projectType: $projectType, mode: $mode, '
        'includePatterns: $includePatterns, excludePatterns: $excludePatterns, '
        'verbose: ${verbose ?? 'unset'}, initConfig: $initConfig, showHelp: $showHelp)';
  }
}
