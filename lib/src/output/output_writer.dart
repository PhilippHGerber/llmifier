import '../config/configuration.dart';
import '../models/project_context.dart';

/// Abstract interface for writing the extracted project context to an output destination.
///
/// This allows for different output formats or destinations in the future.
abstract class OutputWriter {
  /// Writes the provided [projectContext] based on the given [config].
  ///
  /// The [projectContext] contains processed files and project metadata.
  /// Implementations should handle potential I/O errors.
  Future<void> write(ProjectContext projectContext, Configuration config);
}
