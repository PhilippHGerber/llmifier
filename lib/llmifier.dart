/// Public entry point for the llmifier library.
///
/// This library primarily exports the main application class [`LlmifierApp`],
/// which is used by the command-line executable and could potentially be used
/// for programmatic integration.
library;

// Export the main application class.
// The `show` keyword explicitly states what is being exported,
// improving clarity. Adjust the path if your file structure differs.
export 'src/app.dart' show LlmifierApp;
