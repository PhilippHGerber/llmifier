import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../models/enums.dart';
import 'configurable_file_group.dart';
import 'configuration.dart';
import 'settings.dart';
import 'sort_by_option.dart';

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
    bool cliVerbose = settings.verbose ?? currentConfig.verbose;

    // Determine the project path to look for the config file
    final String projectPath =
        settings.projectPath ?? currentConfig.projectPath;
    final String configFilePath = path.join(projectPath, _configFileName);
    final configFile = File(configFilePath);

    if (cliVerbose) {
      print('Looking for configuration file at: $configFilePath');
    }

    // 2. Attempt to load and merge from configuration file
    Map<String, dynamic>? yamlData;
    if (configFile.existsSync()) {
      if (cliVerbose) {
        print('Found configuration file. Attempting to load...');
      }
      try {
        yamlData = _loadYamlFile(configFile);
        // Merge base settings first (output, projectPath, mode, etc.)
        currentConfig = _mergeBaseSettingsWithYaml(
          currentConfig,
          yamlData,
          cliVerbose,
        );
        // Now merge fileOrderingGroups specifically
        currentConfig = _mergeFileOrderingGroupsWithYaml(
          currentConfig,
          yamlData,
          cliVerbose,
        );

        if (currentConfig.verbose) {
          // Use verbosity from potentially loaded config
          print('Successfully loaded and merged configuration from file.');
        }
      } catch (e) {
        stderr.writeln(
          'Warning: Could not load or parse configuration file "$_configFileName": $e',
        );
        stderr.writeln('Continuing with default settings and CLI arguments.');
      }
    } else {
      if (cliVerbose) {
        print(
          'Configuration file not found. '
          'Using defaults and CLI arguments.',
        );
      }
    }

    // 3. Merge with CLI settings (highest priority for base settings)
    // FileOrderingGroups are NOT overridden by CLI in this design.
    final finalConfig = _mergeBaseSettingsWithCli(currentConfig, settings);

    // Dynamically add the output file itself to the exclude list
    final String outputFileName = path.basename(finalConfig.outputPath);
    final updatedExcludePatterns =
        List<String>.from(finalConfig.excludePatterns);
    if (!updatedExcludePatterns.contains(outputFileName) &&
        !outputFileName.contains('*')) {
      updatedExcludePatterns.add(outputFileName); // Add specific output file
    } else if (!updatedExcludePatterns.any(
          (p) => Glob(p).matches(outputFileName),
        ) &&
        outputFileName.contains('*')) {
      // Handle if outputPath is a pattern itself, ensure it's excluded
      updatedExcludePatterns.add(outputFileName);
    }

    return Configuration(
      outputPath: finalConfig.outputPath,
      projectPath: finalConfig.projectPath,
      projectType: finalConfig.projectType,
      mode: finalConfig.mode,
      includePatterns: finalConfig.includePatterns,
      excludePatterns: updatedExcludePatterns,
      verbose: finalConfig.verbose,
      fileOrderingGroups: finalConfig.fileOrderingGroups,
    );
  }

  Map<String, dynamic> _loadYamlFile(File file) {
    final String yamlString = file.readAsStringSync();
    final dynamic yamlContent = loadYaml(yamlString);

    if (yamlContent is YamlMap) {
      // Convert YamlMap to standard Dart Map<String, dynamic>
      return _convertYamlMapToDartMap(yamlContent);
    } else if (yamlContent == null) {
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
    }
    return node;
  }

  /// Merges configuration from a YAML map into the current configuration.
  Configuration _mergeBaseSettingsWithYaml(
    Configuration baseConfig,
    Map<String, dynamic> yamlData,
    bool verboseLog,
  ) {
    T? getYamlValue<T>(String key, T? defaultValue) {
      final value = yamlData[key];
      if (value is T) return value;
      if (value != null && verboseLog) {
        print("YAML: Invalid type for '$key'. "
            "Expected $T, got ${value.runtimeType}. Using base.");
      }
      return defaultValue;
    }

    // Helper function to safely get List<String>
    List<String>? getYamlStringList(String key) {
      final value = yamlData[key];
      if (value is List) {
        if (value.every((item) => item is String)) {
          return List<String>.from(value);
        }
        if (verboseLog) {
          print("YAML: List for '$key' has non-string elements. Ignoring.");
        }
      } else if (value != null && verboseLog) {
        print(
            "YAML: Invalid type for '$key'. Expected List, got ${value.runtimeType}. Ignoring.");
      }
      return null;
    }

    ProjectType projectType = baseConfig.projectType;
    final String? yamlProjectType = getYamlValue<String>('projectType', null);
    if (yamlProjectType != null) {
      try {
        projectType = ProjectType.values.byName(yamlProjectType.toLowerCase());
      } catch (_) {
        if (verboseLog) {
          print(
            "YAML: Invalid value '$yamlProjectType' "
            "for 'projectType'. Using base.",
          );
        }
      }
    }

    ExtractionMode mode = baseConfig.mode;
    final String? yamlMode = getYamlValue<String>('mode', null);
    if (yamlMode != null) {
      try {
        mode = ExtractionMode.values.byName(yamlMode.toLowerCase());
      } catch (_) {
        if (verboseLog) {
          print("YAML: Invalid value '$yamlMode' for 'mode'. Using base.");
        }
      }
    }

    return Configuration(
      outputPath: getYamlValue<String>('output', baseConfig.outputPath) ??
          baseConfig.outputPath,
      projectPath: getYamlValue<String>('project', baseConfig.projectPath) ??
          baseConfig.projectPath,
      projectType: projectType,
      mode: mode,
      includePatterns:
          getYamlStringList('include') ?? baseConfig.includePatterns,
      excludePatterns:
          getYamlStringList('exclude') ?? baseConfig.excludePatterns,
      verbose: getYamlValue<bool>('verbose', baseConfig.verbose) ??
          baseConfig.verbose,
      fileOrderingGroups: baseConfig.fileOrderingGroups,
    );
  }

  Configuration _mergeFileOrderingGroupsWithYaml(Configuration baseConfig,
      Map<String, dynamic> yamlData, bool verboseLog) {
    final fileOrderingSection = yamlData['fileOrdering'];
    if (fileOrderingSection is! Map<String, dynamic>) {
      if (fileOrderingSection != null && verboseLog) {
        print(
          "YAML: 'fileOrdering' section is not a map. "
          "Using default/previous groups.",
        );
      }
      return baseConfig; // No valid section, return base
    }

    final groupsData = fileOrderingSection['groups'];
    if (groupsData is! List) {
      if (groupsData != null && verboseLog) {
        print(
          "YAML: 'fileOrdering.groups' is not a list. "
          "Using default/previous groups.",
        );
      }
      return baseConfig; // No valid groups list, return base
    }

    final List<ConfigurableFileGroup> loadedGroups = [];
    for (final groupEntry in groupsData) {
      if (groupEntry is! Map<String, dynamic>) {
        if (verboseLog) {
          print(
            "YAML: Entry in 'fileOrdering.groups' is not a map. "
            "Skipping entry.",
          );
        }
        continue;
      }

      final String? name = groupEntry['name'] as String?;
      final List<dynamic>? patternsDynamic =
          groupEntry['patterns'] as List<dynamic>?;
      final List<dynamic>? orderDynamic = groupEntry['order'] as List<dynamic>?;
      final String? sortByString = groupEntry['sortBy'] as String?;

      if (name == null || name.isEmpty) {
        if (verboseLog) {
          print(
            "YAML: Group missing 'name' or name is empty. "
            "Skipping group.",
          );
        }
        continue;
      }
      if (patternsDynamic == null ||
          patternsDynamic.isEmpty ||
          !patternsDynamic.every((p) => p is String)) {
        if (verboseLog) {
          print(
            "YAML: Group '$name' missing 'patterns', patterns empty, or not all strings. "
            "Skipping group.",
          );
        }
        continue;
      }
      final List<String> patterns = List<String>.from(patternsDynamic);
      final List<String> order =
          (orderDynamic != null && orderDynamic.every((o) => o is String))
              ? List<String>.from(orderDynamic)
              : const []; // Default to empty if invalid or not present

      SortByOption sortBy = SortByOption.alphabetical; // Default
      if (sortByString != null) {
        try {
          sortBy = SortByOption.values.byName(sortByString.toLowerCase());
        } catch (_) {
          if (verboseLog) {
            print(
              "YAML: Group '$name' has invalid 'sortBy' value '$sortByString'. "
              "Using default '${sortBy.name}'.",
            );
          }
        }
      }
      loadedGroups.add(ConfigurableFileGroup(
        name: name,
        patterns: patterns,
        order: order,
        sortBy: sortBy,
      ));
    }

    if (loadedGroups.isEmpty && groupsData.isNotEmpty && verboseLog) {
      print(
        "YAML: 'fileOrdering.groups' was present but no valid groups could be loaded. "
        "Using default/previous groups.",
      );
      return baseConfig;
    }
    if (loadedGroups.isEmpty && groupsData.isEmpty && verboseLog) {
      // This is fine, means user wants to clear default groups or provided an empty list
      print(
        "YAML: 'fileOrdering.groups' is empty. "
        "All files will fall into a default 'Other' group or be unsorted if no catch-all.",
      );
    }

    // If any groups were successfully loaded from YAML, they REPLACE the default groups.
    // If 'fileOrdering.groups' was present but empty or invalid, use baseConfig.fileOrderingGroups (which are defaults).
    // If 'fileOrdering.groups' was valid and empty, loadedGroups will be empty, effectively clearing default groups.
    return Configuration(
        outputPath: baseConfig.outputPath,
        projectPath: baseConfig.projectPath,
        projectType: baseConfig.projectType,
        mode: baseConfig.mode,
        includePatterns: baseConfig.includePatterns,
        excludePatterns: baseConfig.excludePatterns,
        verbose: baseConfig.verbose,
        fileOrderingGroups: loadedGroups.isNotEmpty || (groupsData.isEmpty)
            ? loadedGroups // Use loaded groups if any, or if explicitly emptied
            : baseConfig
                .fileOrderingGroups // Fallback to base (defaults) if section was missing or invalid
        );
  }

  Configuration _mergeBaseSettingsWithCli(
    Configuration baseConfig,
    Settings settings,
  ) {
    ProjectType projectType = baseConfig.projectType;
    if (settings.projectType != null) {
      try {
        projectType = ProjectType.values.byName(
          settings.projectType!.toLowerCase(),
        );
      } catch (_) {
        if (settings.verbose ?? baseConfig.verbose) {
          print("CLI: Invalid value '${settings.projectType}' "
              "for '--project-type'. Ignoring.");
        }
      }
    }

    ExtractionMode mode = baseConfig.mode;
    if (settings.mode != null) {
      try {
        mode = ExtractionMode.values.byName(settings.mode!.toLowerCase());
      } catch (_) {
        if (settings.verbose ?? baseConfig.verbose) {
          print("CLI: Invalid value '${settings.mode}' "
              "for '--mode'. Ignoring.");
        }
      }
    }

    return Configuration(
      outputPath: settings.outputPath ?? baseConfig.outputPath,
      projectPath: settings.projectPath ?? baseConfig.projectPath,
      projectType: projectType,
      mode: mode,
      includePatterns: settings.includePatterns.isNotEmpty
          ? settings.includePatterns
          : baseConfig.includePatterns,
      excludePatterns: settings.excludePatterns.isNotEmpty
          ? settings.excludePatterns
          : baseConfig.excludePatterns,
      verbose: settings.verbose ?? baseConfig.verbose,
      fileOrderingGroups: baseConfig
          .fileOrderingGroups, // CLI does not override fileOrderingGroups
    );
  }
}
