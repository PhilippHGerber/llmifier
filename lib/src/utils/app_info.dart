import 'package:llmifier/src/version.dart';

/// Provides static information about the llmifier application itself.
///
/// Used primarily for generating the output file footer.
class AppInfo {
  /// The current version of the llmifier tool.
  static const String version = packageVersion; // Placeholder version

  /// The author or maintainer of the tool.
  static const String author = 'Software Engineering Philipp Gerber';

  /// The URL to the tool's repository.
  static const String repositoryUrl =
      'https://github.com/PhilippHGerber/llmifier';

  /// The URL to the tool's package page (e.g., on pub.dev).
  static const String packageUrl = 'https://pub.dev/packages/llmifier';
}
