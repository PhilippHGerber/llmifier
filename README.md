# llmifier • [![pub package](https://img.shields.io/pub/v/llmifier.svg)](https://pub.dev/packages/llmifier) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Transform your Dart & Flutter projects into optimized LLM context – get better code generation, more insightful reviews, and precise answers.**

<p align="center">
  <img src="https://raw.githubusercontent.com/PhilippHGerber/llmifier/main/images/llmifier-flow.webp" alt="llmifier workflow" width="600">
</p>

## What llmifier Does

llmifier extracts and organizes your Dart/Flutter code into a single file that LLMs can understand perfectly:

- ✅ **Smart Context Compression** - Feed entire projects to LLMs, even with limited context windows
- ✅ **Semantic Organization** - Files ordered logically (Docs → Config → API → Tests) for optimal comprehension
- ✅ **Version Tracking** - Each file tagged with package version for accurate historical analysis
- ✅ **API Focus** - Extract either full code or just public API surface with documentation
- ✅ **Developer-Friendly** - Simple CLI workflow integrates with your existing development process

## Quick Start

```bash
# Install globally
dart pub global activate llmifier

# Run in your project directory
llmifier

# That's it! Find your LLM-ready project in llms.txt
```

## Example: From Fragmented Files to LLM-Ready Context

```
📁 Your Flutter Project      ➡️   📄 Single LLM-Optimized File
├── README.md                     <!-- BEGIN FILE: [v1.2.3] README.md -->
├── pubspec.yaml                  # Project documentation...
├── lib/                          <!-- END FILE: [v1.2.3] README.md -->
│   ├── main.dart
│   └── src/                      <!-- BEGIN FILE: [v1.2.3] pubspec.yaml -->
│       ├── models.dart           # Package configuration...
│       └── utils.dart            <!-- END FILE: [v1.2.3] pubspec.yaml -->
└── test/
    └── widget_test.dart          <!-- BEGIN FILE: [v1.2.3] lib/main.dart -->
                                  # Main app code...
                                  <!-- END FILE: [v1.2.3] lib/main.dart -->

                                  <!-- BEGIN FILE: [v1.2.3] lib/src/models.dart -->
                                  # Model definitions...
                                  <!-- END FILE: [v1.2.3] lib/src/models.dart -->
```

## Command Options

```bash
# Generate API-only output with cleaner context
llmifier -m api -o llms-api.txt

# Process a specific project directory
llmifier -p path/to/your/project

# Generate a default config file
llmifier -i

# See all options
llmifier -h
```

## How Developers Use llmifier

### For Code Generation

Structure your whole project context to get precise, relevant code generation that fits your architecture and styles:

```
# Create feature with project context
1. Run: llmifier
2. Paste llms.txt into your LLM
3. Prompt: "Add a user authentication feature matching our existing architecture"
```

### For Code Reviews

Get meaningful, holistic code reviews that understand your entire project:

```
# Compare versions for insightful review
1. Run: llmifier on version 1.0
2. Run: llmifier on version 1.1
3. Prompt: "What architectural changes were made between these versions?"
```

### For Documentation

Generate comprehensive documentation based on actual code structure:

```
# Create targeted API documentation
1. Run: llmifier -m api
2. Prompt: "Create developer documentation for our public API"
```

### For Onboarding

Help new team members (or your LLM assistant) quickly understand your codebase:

```
# Create onboarding guide
1. Run: llmifier
2. Prompt: "Explain the architecture and key components of this project"
```

## Customizing Extraction

Create a `llmifierrc.yaml` in your project root (or generate one with `llmifier -i`):

```yaml
# Basic configuration
mode: api  # 'full' or 'api'
output: project-context.txt

# File selection patterns
include:
  - "**README.md"
  - "**lib/**.dart"
  - "**test/integration/**.dart"

exclude:
  - "**build"
  - "**.g.dart"
```

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/PhilippHGerber/llmifier).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
