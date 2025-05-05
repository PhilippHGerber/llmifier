import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart'; // For AnalysisError

// Local imports
import '../models/enums.dart';
import 'api_extractor_visitor.dart';
import 'content_processor.dart';

class DartContentProcessor implements ContentProcessor {
  @override
  String processContent(String relativePath, String content, ExtractionMode mode) {
    switch (mode) {
      case ExtractionMode.full:
        return content;

      case ExtractionMode.api:
        try {
          // Errors are accessed via the result object.
          final parseResult = parseString(
            content: content,
            path: relativePath, // Providing path is good practice
            throwIfDiagnostics: false, // Don't throw on parse errors
          );

          // Filter for actual errors, not hints/warnings if desired
          final List<AnalysisError> parseErrors =
              parseResult.errors.where((e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR).toList();

          if (parseErrors.isNotEmpty) {
            stderr.writeln(
                "Warning: Could not fully parse '$relativePath' due to errors. API extraction might be incomplete "
                "or incorrect. Falling back to original content for this file.");
            // for (final error in parseErrors) {
            //   stderr.writeln("  - Error Code: ${error.errorCode.name}");
            //   stderr.writeln("  - Message: ${error.message}");
            //   stderr.writeln("  - Offset: ${error.offset}, Length: ${error.length}");
            // }
            return content; 
          }

          final compilationUnit = parseResult.unit;

          final visitor = ApiExtractorVisitor(content);

          compilationUnit.accept(visitor);

          return visitor.apiOutput.toString();
        } catch (e, stackTrace) {
          stderr.writeln("Error processing API for '$relativePath': $e");
          stderr.writeln(stackTrace);

          return content;
        }
    }
  }
}

// Removed _SilentErrorListener as it's no longer needed here
