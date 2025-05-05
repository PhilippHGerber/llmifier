# llmifier • [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**A Dart CLI tool to extract, structure, and consolidate Dart & Flutter project files into a single, LLM-friendly context.**

---

## Key Features

* 🎯 **Targeted Extraction:** Focuses on Dart/Flutter projects, understanding typical structures (`lib/`, `bin/`, `test/`, etc.).
* ⚙️ **Flexible Filtering:** Uses `glob` patterns (like `.gitignore`) for precise control over included and excluded files.
* 🧠 **Semantic Ordering:** Prioritizes files logically (Docs, Metadata, API, etc.) for improved LLM comprehension (customizable via config).
* 🏷️ **Per-File Versioning:** Embeds the `pubspec.yaml` version in each file marker (`<!-- BEGIN FILE [vX.Y.Z]: path/to/file -->`) for unambiguous context.
* ✨ **Extraction Modes:**
  * `full`: Extracts the complete content of matched files.
  * `api`: Extracts only the public API surface (classes, functions, variables) along with documentation comments, powered by the `analyzer` package. Ideal for providing usage context.
* 🔧 **Configuration:** Uses a clear `llmifierrc.yaml` file alongside CLI arguments (CLI overrides YAML, which overrides defaults).
* 🚀 **Init Command:** Quickly generates a default `llmifierrc.yaml` configuration file (`llmifier --init`).

## Installation

### Global Activation for CLI usage

```bash
dart pub global activate llmifier
```

Now you can run `llmifier` from anywhere.

## Usage

```bash
# Generate output in the current directory (default: llms.txt)
llmifier

# Specify output file
llmifier -o my_project_context.txt

# Specify project directory
llmifier -p path/to/your/project

# Use API extraction mode
llmifier -m api

# Use API mode with a specific output file
llmifier --mode=api --output=llms-api.txt

# Get verbose logging during processing
llmifier -l

# Generate a default config file in the current directory
llmifier -i

# Show help message
llmifier -h
```

**Why the `[v1.2.3]` tag in markers?**
This small detail is vital! It ensures the LLM always knows exactly which version of your code a specific file belongs to, preventing confusion when analyzing changes or comparing different versions side-by-side.

## Configuration (`llmifierrc.yaml`)

Create a `llmifierrc.yaml` file in your project root (or generate one using `llmifier --init`) to customize behavior.

**Configuration Hierarchy:** CLI Arguments > `llmifierrc.yaml` > Default Settings

## Use Cases

* **LLM Code Generation:** Provide comprehensive project context for generating new features or fixing bugs.
* **LLM Code Review:** Give the LLM a structured overview for more accurate analysis and suggestions.
* **LLM-Powered Documentation:** Generate technical documentation or summaries based on the actual codebase structure.
* **Onboarding:** Help new team members (or an LLM assistant) quickly grasp the project layout and key components.
* **Version Comparison:** Feed outputs from two different versions to an LLM for detailed change analysis.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/PhilippHGerber/llmifier).

## Reporting Issues

Please report any bugs or feature requests on the [GitHub issue tracker](https://github.com/PhilippHGerber/llmifier/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
