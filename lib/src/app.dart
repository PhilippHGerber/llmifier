import 'dart:io';

import 'config/argument_parser.dart';
import 'config/config_generator.dart';
import 'config/config_loader.dart';
import 'config/configuration.dart';
import 'config/settings.dart';
import 'extraction/file_extractor.dart';
import 'output/text_output_writer.dart';
import 'processing/project_processor.dart';

/// The main application class responsible for orchestrating the llmifier process.
class LlmifierApp {
  /// Runs the llmifier tool logic based on the provided command line arguments.
  ///
  /// Returns an exit code (0 for success, non-zero for errors).
  Future<int> run(List<String> arguments) async {
    final argumentParser = ArgumentParser();
    Settings settings;
    Configuration configuration;
    // Determine initial verbosity from CLI args for early messages like --init
    bool isInitVerbose =
        arguments.contains('-l') || arguments.contains('--verbose');

    try {
      // 1. Parse CLI arguments
      settings = argumentParser.parse(arguments);

      // Handle --help flag early
      if (settings.showHelp) {
        argumentParser.printUsage();
        return 0; // Success exit code for help
      }

      // --- Handle --init flag early ---
      if (settings.initConfig) {
        print('Configuration file generation requested...');
        final projectDirForInit = settings.projectPath ?? '.';
        final generator = ConfigGenerator();
        final success = await generator.generateDefaultConfig(
          projectDirForInit,
          verbose: isInitVerbose,
        );
        // Exit after attempting generation, return 0 for success, 1 for failure/skip
        return success ? 0 : 1;
      }
      // --- End --init handling ---

      // Print parsed settings if verbose (useful for debugging config loading)
      // Use the potentially updated verbose setting from the parsed settings
      bool isConfigLoadVerbose = settings.verbose ?? false;
      if (isConfigLoadVerbose) {
        print('Parsed CLI Settings: $settings');
      }
    } on FormatException {
      // Error message already printed by parser, usage shown
      return 1; // Indicate failure due to parsing error
    } catch (e, stackTrace) {
      // Catch potential errors during parsing itself
      stderr
          .writeln('An unexpected error occurred during argument parsing: $e');
      // Print stacktrace only if explicitly requested early on
      if (isInitVerbose) {
        stderr.writeln(stackTrace);
      }
      return 1;
    }
    // --- End Argument Parsing Block ---

    // --- Main Execution Block (Loading Config, Extraction, etc.) ---
    // Reset verbosity, will be set by loaded config
    bool isVerbose = false;
    try {
      // 2. Load configuration (using the parsed settings)
      if (settings.verbose ?? false) print('Loading configuration...');
      final configLoader = ConfigLoader();
      configuration = configLoader.load(settings);

      // Use configuration's verbose flag from now on for main process
      isVerbose = configuration.verbose;

      if (isVerbose) {
        print('Effective Configuration loaded:');
        print(configuration.toString());
        print('---'); // Separator
      }

      // 3. Extract files
      if (isVerbose) print('Proceeding with file extraction...');
      final fileExtractor = FileExtractor(configuration);
      final rawFiles = fileExtractor.extractFiles();
      if (isVerbose) print('Extracted ${rawFiles.length} raw files.');

      // 4. Process & Organize Files
      if (isVerbose) {
        print('Proceeding with project processing and file ordering...');
      }
      final projectProcessor = ProjectProcessor(configuration);
      final projectContext = projectProcessor.process(rawFiles);
      if (isVerbose) print('Processing and ordering complete.');

      // 5. Write Output
      if (isVerbose) print('Proceeding with output generation...');
      final outputWriter = TextOutputWriter();
      await outputWriter.write(projectContext, configuration);
      print('Output generated successfully at: ${configuration.outputPath}');

      // If everything completes successfully
      return 0;
    } catch (e, stackTrace) {
      // Catch specific expected exceptions (e.g., FileSystemException during load/extract/write)
      stderr.writeln('An error occurred during execution: $e');
      // Print stack trace if verbose is enabled (using final config setting)
      if (isVerbose) {
        stderr.writeln(stackTrace);
      } else {
        // Optionally add hint to use -v for more details
        stderr.writeln('(Run with -v for more details)');
      }

      // Consider printing usage info on specific argument errors (less likely here now)
      // if (e is ArgumentError) { ArgumentParser().printUsage(); }
      return 1; // Indicate failure
    }
  }
}
