/// Defines the available strategies for sorting files within a [ConfigurableFileGroup].
enum SortByOption {
  /// Sorts files alphabetically by their relative path.
  alphabetical,

  /// Sorts files first by directory depth (ascending), then alphabetically.
  /// Ideal for source code directories like 'lib/' or 'test/'.
  depthFirst,
}
