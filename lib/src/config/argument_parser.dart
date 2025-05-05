import 'dart:io';

import 'package:args/args.dart';

import 'settings.dart'; // Import the Settings class

/// Handles parsing of command-line arguments for the llmifier tool.
class ArgumentParser {
  /// Creates and configures the command-line argument parser.
  ArgParser createParser() {
    return ArgParser()
      // Output Options
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Specify the output file path.\n(e.g., llms-output.txt)',
      )
      ..addOption(
        'project',
        abbr: 'p',
        help: 'Specify the project directory path.\n(Defaults to the current directory)',
      )

      // Extraction Options
      ..addOption(
        'mode',
        abbr: 'm',
        help: 'Set the extraction mode.',
        allowed: ['full', 'api'], // Enforce allowed values
        // Default value will be handled by Configuration merging
      )
      ..addOption(
        'project-type',
        abbr: 't',
        help: 'Set the project type (influences default file ordering).',
        allowed: ['dart', 'flutter'], // Enforce allowed values
        // Default value will be handled by Configuration merging
      )
      ..addMultiOption(
        'include',
        help: 'Glob pattern for files/directories to include.\n(Can be specified multiple times)',
      )
      ..addMultiOption(
        'exclude',
        help: 'Glob pattern for files/directories to exclude.\n(Can be specified multiple times)',
      )

      // Control Flags
      ..addFlag(
        'verbose',
        abbr: 'l',
        negatable: false,
        help: 'Enable verbose logging output.',
      )
      ..addFlag(
        'init',
        abbr: 'i',
        negatable: false,
        help: 'Generate a default llmifierrc.yaml configuration file in the project directory.',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show this help message.',
      );
    // Note: 'includePrivate' is not a direct CLI flag in v1.0 spec,
    // it's handled by the Configuration logic based on mode etc.
  }

  /// Parses the command-line arguments and returns a [Settings] object.
  ///
  /// Throws [FormatException] if parsing fails.
  Settings parse(List<String> arguments) {
    final parser = createParser();
    final ArgResults results;

    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      // Provide context for the format exception
      stderr.writeln('Error parsing arguments: ${e.message}');
      printUsage();
      // Re-throw or handle appropriately - re-throwing allows main to catch it
      rethrow;
    }

    // Handle help flag immediately if present
    if (results['help'] as bool) {
      // Return a Settings object indicating help was requested
      return const Settings(
        includePatterns: [],
        excludePatterns: [],
        verbose: null,
        initConfig: false,
        showHelp: true, // The important flag
      );
    }

    // Extract values from ArgResults
    return Settings(
      outputPath: results['output'] as String?,
      projectPath: results['project'] as String?,
      projectType: results['project-type'] as String?,
      mode: results['mode'] as String?,
      includePatterns: results['include'] as List<String>,
      excludePatterns: results['exclude'] as List<String>,
      verbose: results.wasParsed('verbose') ? (results['verbose'] as bool) : null,
      initConfig: results['init'] as bool,
      showHelp: false, // Already handled above
    );
  }

  /// Prints usage information based on the configured argument parser.
  void printUsage() {
    final parser = createParser();
    print('llmifier - Extracts and prepares project files for LLMs.');
    print('');
    print('Usage: llmifier [options]');
    print('');
    print('Options:');
    print(parser.usage);
  }
}
