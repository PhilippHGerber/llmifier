import 'dart:io';

import 'package:llmifier/llmifier.dart';

/// Application entry point.
///
/// Parses command line arguments, runs the main application logic,
/// and handles global errors.
Future<void> main(List<String> arguments) async {
  int exitCode = 0;

  try {
    print('Starting llmifier...');

    // Instantiate the main application class
    final app = LlmifierApp();

    // Run the application logic and get the exit code
    exitCode = await app.run(arguments);

    print('llmifier finished successfully.');
  } catch (e, stackTrace) {
    // Handle expected errors (like ArgumentError from parsing)
    // or unexpected errors gracefully.
    stderr.writeln('Error: $e');
    // Optionally print stack trace for unexpected errors in debug/verbose mode
    // check for  debug mode
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      stderr.writeln('Stack trace:');
      stderr.writeln(stackTrace);
    } else {
      // In production mode, you might want to log the error to a file or monitoring service
      File('llmifier_log.txt').writeAsStringSync(
        '$e\n$stackTrace',
        mode: FileMode.append,
      );
    }
    exitCode = 1;
    print('llmifier finished with errors.');
  } finally {
    // Ensure the application exits with the determined exit code.
    exit(exitCode);
  }
}
