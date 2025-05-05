import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../models/enums.dart';
// Local imports
import 'configuration.dart';
import 'settings.dart';

/// Loads and merges configuration settings from defaults, a configuration file,
/// and command-line arguments.
class ConfigLoader {
  static const String _configFileName = 'llmifierrc.yaml';

  /// Loads the final [Configuration] by merging settings sources hierarchically.
  ///
  /// Hierarchy (highest priority last):
  /// 1. Default values ([Configuration.defaults])
  /// 2. Configuration file (`llmifierrc.yaml`)
  /// 3. Command-line arguments ([Settings])
  ///
  /// Takes the raw [Settings] parsed from CLI arguments.
  Configuration load(Settings settings) {
    // 1. Start with default configuration
    Configuration currentConfig = Configuration.defaults();

    // Determine the project path to look for the config file
    // Use CLI path if provided, otherwise default ('.')
    final String projectPath = settings.projectPath ?? currentConfig.projectPath;
    final String configFilePath = path.join(projectPath, _configFileName);
    final configFile = File(configFilePath);

    if (settings.verbose ?? false) {
      print('Looking for configuration file at: $configFilePath');
    }

    // 2. Attempt to load and merge from configuration file
    if (configFile.existsSync()) {
      if (settings.verbose ?? false) {
        print('Found configuration file. Attempting to load...');
      }
      try {
        final yamlMap = _loadYamlFile(configFile);
        currentConfig = _mergeWithYaml(currentConfig, yamlMap, settings.verbose ?? false);
        if (currentConfig.verbose) {
          print('Successfully loaded and merged configuration from file.');
        }
      } catch (e) {
        // Warn the user but continue with defaults/CLI args
        stderr.writeln('Warning: Could not load or parse configuration file "$_configFileName": $e');
        stderr.writeln('Continuing with default settings and CLI arguments.');
      }
    } else {
      if (settings.verbose ?? false) {
        print('Configuration file not found. Using defaults and CLI arguments.');
      }
    }

    // 3. Merge with CLI settings (highest priority)
    // We pass the original 'settings' object and the 'currentConfig' which
    // now contains defaults potentially overridden by the config file.
    final finalConfig = _mergeWithCliSettings(currentConfig, settings);

    // Dynamically add the output file itself to the exclude list
    // to prevent llmifier from reading its own previous output.
    // Do this *after* all merging is complete.
    final String outputFileName = path.basename(finalConfig.outputPath);
    final updatedExcludePatterns = List<String>.from(finalConfig.excludePatterns);
    if (!updatedExcludePatterns.contains(outputFileName)) {
      updatedExcludePatterns.add(outputFileName);
    }

    // Return a final configuration with the updated exclude list
    return Configuration(
        outputPath: finalConfig.outputPath,
        projectPath: finalConfig.projectPath,
        projectType: finalConfig.projectType,
        mode: finalConfig.mode,
        includePatterns: finalConfig.includePatterns,
        excludePatterns: updatedExcludePatterns, // Use the updated list
        verbose: finalConfig.verbose);
  }

  /// Loads and parses a YAML file into a Dart Map.
  Map<String, dynamic> _loadYamlFile(File file) {
    final String yamlString = file.readAsStringSync();
    final dynamic yamlContent = loadYaml(yamlString);

    if (yamlContent is YamlMap) {
      // Convert YamlMap to standard Dart Map<String, dynamic>
      return _convertYamlMapToDartMap(yamlContent);
    } else if (yamlContent == null) {
      // Handle empty file case gracefully
      return <String, dynamic>{};
    } else {
      throw FormatException('Configuration file content must be a YAML map.');
    }
  }

  /// Recursively converts a YamlMap to a standard Dart Map.
  Map<String, dynamic> _convertYamlMapToDartMap(YamlMap yamlMap) {
    final Map<String, dynamic> map = {};
    yamlMap.forEach((key, value) {
      if (key is String) {
        map[key] = _convertYamlNodeToDartObject(value);
      }
      // Ignore non-string keys if any
    });
    return map;
  }

  /// Recursively converts a YamlList to a standard Dart List.
  List<dynamic> _convertYamlListToDartList(YamlList yamlList) {
    return yamlList.map(_convertYamlNodeToDartObject).toList();
  }

  /// Converts any YAML node to its Dart equivalent.
  dynamic _convertYamlNodeToDartObject(dynamic node) {
    if (node is YamlMap) {
      return _convertYamlMapToDartMap(node);
    } else if (node is YamlList) {
      return _convertYamlListToDartList(node);
    } else {
      // Handles scalars like String, bool, int, double, null
      return node;
    }
  }

  /// Merges configuration from a YAML map into the current configuration.
  Configuration _mergeWithYaml(Configuration baseConfig, Map<String, dynamic> yamlData, bool verbose) {
    // Helper function to safely get typed values from YAML map
    T? getYamlValue<T>(String key, T? defaultValue) {
      final value = yamlData[key];
      if (value is T) {
        return value;
      } else if (value != null && verbose) {
        print(
            "YAML config: Invalid type for key '$key'. Expected $T, got ${value.runtimeType}. Using default/previous value.");
      }
      return defaultValue;
    }

    // Helper function to safely get List<String>
    List<String>? getYamlStringList(String key) {
      final value = yamlData[key];
      if (value is List) {
        // Ensure all elements are strings
        if (value.every((item) => item is String)) {
          return List<String>.from(value);
        } else if (verbose) {
          print("YAML config: List for key '$key' contains non-string elements. Ignoring list.");
        }
      } else if (value != null && verbose) {
        print("YAML config: Invalid type for key '$key'. Expected List, got ${value.runtimeType}. Ignoring value.");
      }
      return null; // Return null if type is wrong or list contains non-strings
    }

    // Parse Enums with safety checks
    ProjectType projectType = baseConfig.projectType;
    final String? yamlProjectType = getYamlValue<String>('projectType', null);
    if (yamlProjectType != null) {
      try {
        projectType = ProjectType.values.byName(yamlProjectType.toLowerCase());
      } catch (_) {
        if (verbose) {
          print("YAML config: Invalid value '$yamlProjectType' for 'projectType'. Using default/previous value.");
        }
      }
    }

    ExtractionMode mode = baseConfig.mode;
    final String? yamlMode = getYamlValue<String>('mode', null);
    if (yamlMode != null) {
      try {
        mode = ExtractionMode.values.byName(yamlMode.toLowerCase());
      } catch (_) {
        if (verbose) print("YAML config: Invalid value '$yamlMode' for 'mode'. Using default/previous value.");
      }
    }

    return Configuration(
      // Use ?? operator to fallback to baseConfig value if YAML value is null or wrong type
      outputPath: getYamlValue<String>('output', baseConfig.outputPath) ?? baseConfig.outputPath,
      projectPath: getYamlValue<String>('project', baseConfig.projectPath) ?? baseConfig.projectPath,
      projectType: projectType, // Use safely parsed enum
      mode: mode, // Use safely parsed enum
      includePatterns: getYamlStringList('include') ?? baseConfig.includePatterns,
      excludePatterns: getYamlStringList('exclude') ?? baseConfig.excludePatterns,
      verbose: getYamlValue<bool>('verbose', baseConfig.verbose) ?? baseConfig.verbose,
      // Note: fileOrdering section from YAML is ignored in Phase 1 loader logic
    );
  }

  /// Merges configuration from CLI [Settings] into the current configuration.
  /// CLI settings have the highest priority.
  Configuration _mergeWithCliSettings(Configuration baseConfig, Settings settings) {
    // Parse Enums from CLI settings if provided
    ProjectType projectType = baseConfig.projectType;
    if (settings.projectType != null) {
      try {
        projectType = ProjectType.values.byName(settings.projectType!.toLowerCase());
      } catch (_) {
        if (settings.verbose ?? baseConfig.verbose) {
          print("CLI config: Invalid value '${settings.projectType}' for '--project-type'. Ignoring.");
        }
        // Optionally throw an error here if CLI enum values must be valid
      }
    }

    ExtractionMode mode = baseConfig.mode;
    if (settings.mode != null) {
      try {
        mode = ExtractionMode.values.byName(settings.mode!.toLowerCase());
      } catch (_) {
        if (settings.verbose ?? baseConfig.verbose) {
          print("CLI config: Invalid value '${settings.mode}' for '--mode'. Ignoring.");
        }
        // Optionally throw an error here if CLI enum values must be valid
      }
    }

    return Configuration(
      // CLI options override only if they were actually provided (not null)
      outputPath: settings.outputPath ?? baseConfig.outputPath,
      projectPath: settings.projectPath ?? baseConfig.projectPath,
      projectType: projectType, // Use safely parsed enum
      mode: mode, // Use safely parsed enum

      // CLI include/exclude patterns *replace* previous ones if provided
      includePatterns: settings.includePatterns.isNotEmpty ? settings.includePatterns : baseConfig.includePatterns,
      excludePatterns: settings.excludePatterns.isNotEmpty ? settings.excludePatterns : baseConfig.excludePatterns,

      // CLI flags always override
      verbose: settings.verbose ?? baseConfig.verbose,
    );
  }
}
