import 'package:llmifier/src/models/enums.dart';
import 'package:llmifier/src/processing/dart_content_processor.dart';
import 'package:test/test.dart';

// Helper function to simplify calling the API extraction logic
String processApi(String sourceContent, {String path = 'test.dart'}) {
  final processor = DartContentProcessor();
  // Process content using API mode
  return processor.processContent(path, sourceContent, ExtractionMode.api);
}

void main() {
  group('API Extraction Tests', () {
    // =========================================================================
    // Basic Declarations Group
    // =========================================================================
    group('Basic Declarations', () {
      test('should extract public class signature without members', () {
        final input = r'''
/// A simple class.
class SimpleClass {}
''';
        // Expect class signature with braces on separate lines
        final expectedOutput = r'''
/// A simple class.
class SimpleClass {
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level function signature', () {
        final input = r'''
/// Adds two numbers.
int add(int a, int b) {
  return a + b; // Implementation should be removed
}
''';
        // Expect signature ending with a semicolon and a newline
        final expectedOutput = r'''
/// Adds two numbers.
int add(int a, int b);
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level getter signature (inferred type)',
          () {
        final input = r'''
/// A global configuration.
get globalConfig => 'default';
''';
        final expectedOutput = r'''
/// A global configuration.
get globalConfig;
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level getter signature (explicit type)',
          () {
        final input = r'''
/// The current user's name.
String get currentUserName {
  return 'Guest';
}
''';
        final expectedOutput = r'''
/// The current user's name.
String get currentUserName;
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level getter (problem file example)', () {
        final input = r'''
ShVersion get shVersion => read(shVersionRef);
''';
        final expectedOutput = r'''
ShVersion get shVersion;
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level setter signature', () {
        final input = r'''
/// Sets the global theme.
set theme(String newTheme) {
  // implementation
}
''';
        final expectedOutput = r'''
/// Sets the global theme.
set theme(String newTheme);
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public top-level variable declaration', () {
        final input = r'''
/// A configuration value.
const int timeout = 1000;
''';
        // For const variables, the initializer is part of the API contract.
        final expectedOutput = r'''
/// A configuration value.
const int timeout = 1000;
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public enum declaration with constants', () {
        final input = r'''
/// Represents the state.
enum Status {
  /// Initial state.
  initial,
  /// Loading state.
  loading,
  /// Success state.
  success,
  /// Failure state.
  failure
}
''';
        // Expect enum signature and constants with commas
        final expectedOutput = r'''
/// Represents the state.
enum Status {
  /// Initial state.
  initial,
  /// Loading state.
  loading,
  /// Success state.
  success,
  /// Failure state.
  failure,
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public mixin signature', () {
        final input = r'''
/// A mixin for logging.
mixin LoggerMixin {
  void log(String message) {
    print('[LOG] $message');
  }
}
''';
        // Expect mixin signature and method signature inside
        final expectedOutput = r'''
/// A mixin for logging.
mixin LoggerMixin {
  void log(String message);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public extension signature', () {
        final input = r'''
/// Extension on String.
extension StringUtils on String {
  /// Checks if the string is empty.
  bool isEmptyOrNull() => this == null || this.isEmpty;
}
''';
        // Expect extension signature and method signature inside
        final expectedOutput = r'''
/// Extension on String.
extension StringUtils on String {
  /// Checks if the string is empty.
  bool isEmptyOrNull();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public extension type declaration', () {
        final input = r'''
/// An extension type for IDs.
extension type UserId(int id) {
  /// Gets the raw ID.
  int get value => id;
}
''';
        // Expect extension type signature and getter signature inside
        final expectedOutput = r'''
/// An extension type for IDs.
extension type UserId(int id) {
  /// Gets the raw ID.
  int get value;
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public function typedef', () {
        final input = r'''
/// Callback for events.
typedef void EventCallback(int eventId);
''';
        // Expect typedef signature
        final expectedOutput = r'''
/// Callback for events.
typedef void EventCallback(int eventId);
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should extract public generic typedef', () {
        final input = r'''
/// A generic result type alias.
typedef Result<T> = ({T? value, String? error});
''';
        // Expect generic typedef signature
        final expectedOutput = r'''
/// A generic result type alias.
typedef Result<T> = ({T? value, String? error});
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Basic Declarations Group

    // =========================================================================
    // Visibility Group
    // =========================================================================
    group('Visibility Tests', () {
      test('should only extract public members from a class', () {
        final input = r'''
/// A class with mixed visibility.
class MixedVisibility {
  /// Public field
  final String publicField;
  final String _privateField; // Should be ignored

  /// Public constructor.
  MixedVisibility(this.publicField, this._privateField);

  /// Public named constructor.
  MixedVisibility.named(this.publicField) : _privateField = '';

  // Private constructor - should be ignored
  MixedVisibility._internal() : publicField = '', _privateField = '';

  /// Public method
  void doPublic() {}

  // Private method - should be ignored
  void _doPrivate() {}

  /// Public getter
  int get publicGetter => 1;

  // Private getter - should be ignored
  int get _privateGetter => 0;
}
''';
        // Expect only public members, including constructors
        final expectedOutput = r'''
/// A class with mixed visibility.
class MixedVisibility {
  /// Public field
  final String publicField;

  /// Public constructor.
  MixedVisibility(this.publicField, this._privateField);

  /// Public named constructor.
  MixedVisibility.named(this.publicField);

  /// Public method
  void doPublic();

  /// Public getter
  int get publicGetter;
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should produce empty output for file with only private members',
          () {
        final input = r'''
/// Library comment
library private_stuff;

// A private class
class _PrivateClass {
  int _value = 0;
  void _run() {}
}

// A private function
String _privateTopLevel() => '';
''';
        // Expect an empty string as there's no public API surface
        final expectedOutput = r'''
'''; // Empty string expected
        expect(processApi(input), equals(expectedOutput));
      });

      test(
          'should keep public function signature even if it returns private type',
          () {
        final input = r'''
        class _PrivateType {}

        /// Returns a private type instance.
        _PrivateType getPrivate() => _PrivateType();
         ''';
        // The signature is public, even if the return type isn't exported well
        final expectedOutput = r'''
/// Returns a private type instance.
_PrivateType getPrivate();
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Visibility Tests group

    // =========================================================================
    // Documentation Comments Group
    // =========================================================================
    group('Documentation Comment Tests', () {
      test('should handle multi-line doc comments correctly', () {
        final input = r'''
        /// This is the first line.
        /// This is the second line.
        ///   Indented line within comment.
        void documentedFunction() {
          // implementation
        }
        ''';
        // Expect the full doc comment preserved with its formatting
        final expectedOutput = r'''
/// This is the first line.
/// This is the second line.
///   Indented line within comment.
void documentedFunction();
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle declarations without doc comments gracefully', () {
        final input = r'''
         class NoDocClass {
           int value; // No doc comment here

           NoDocClass(this.value); // No doc comment here

           void performAction() { /* No doc */ }
         }
         ''';
        // Expect signatures without preceding comments, correct spacing.
        // Visitor might add a newline before members if previous one had comment.
        final expectedOutput = r'''
class NoDocClass {
  int value;

  NoDocClass(this.value);

  void performAction();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should preserve doc comments on enum constants', () {
        final input = r'''
          enum State {
            /// The initial state.
            initial,
            // No doc here
            loading,
            /// The final state.
            done
          }
          ''';
        final expectedOutput = r'''
enum State {
  /// The initial state.
  initial,
  loading,
  /// The final state.
  done,
}
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Documentation Comment Tests group

    // =========================================================================
    // Signatures and Details Group
    // =========================================================================
    group('Signatures and Details', () {
      test('should handle various parameter types', () {
        final input = r'''
/// A function with various parameters.
void process(
  int positional,
  [String? optionalPositional, bool flag = true]
) {
  // impl
}

/// Another function with named parameters.
void configure({
  required String name,
  int? count,
  bool enabled = false
}) {
  // impl
}
''';
        // Expect signatures, default values are removed in API view
        final expectedOutput = r'''
/// A function with various parameters.
void process(
  int positional,
  [String? optionalPositional, bool flag = true]
);

/// Another function with named parameters.
void configure({
  required String name,
  int? count,
  bool enabled = false
});
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle different return types and generics', () {
        final input = r'''
           /// Async fetch.
           Future<String> fetchData<T>(T id) async => 'data';

           /// Void function.
           void doNothing() {}

           /// Generic class.
           class Repository<T extends Object> {
             /// Find by ID.
             Future<T?> findById(String id) async => null;
           }
           ''';
        final expectedOutput = r'''
/// Async fetch.
Future<String> fetchData<T>(T id);

/// Void function.
void doNothing();

/// Generic class.
class Repository<T extends Object> {
  /// Find by ID.
  Future<T?> findById(String id);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle field modifiers', () {
        final input = r'''
           class ModifiersExample {
             final String immutable;
             static const int compileConstant = 0;
             late String initializedLater;
             String mutable;
             static String staticMutable = '';

             ModifiersExample(this.immutable, this.mutable);
           }
           ''';
        // Expect declarations keeping modifiers
        // Keep initializer for 'static const', remove for 'static String'.
        // Expect NO extra blank lines between fields or before constructor.
        final expectedOutput = r'''
class ModifiersExample {
  final String immutable;
  static const int compileConstant = 0;
  late String initializedLater;
  String mutable;
  static String staticMutable;

  ModifiersExample(this.immutable, this.mutable);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle method modifiers (static, abstract)', () {
        final input = r'''
           abstract class ModifierMethods {
             /// Static factory method.
             static ModifierMethods create() => _Concrete();

             /// Abstract method to implement.
             void process();
           }

           class _Concrete implements ModifierMethods {
             @override
             void process() {}
           }
           ''';
        // Expect static method and abstract method signatures
        final expectedOutput = r'''
abstract class ModifierMethods {
  /// Static factory method.
  static ModifierMethods create();

  /// Abstract method to implement.
  void process();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle getters and setters', () {
        final input = r'''
           class GetSet {
             int _value = 0;

             /// The current value.
             int get value => _value;

             /// Set a new value.
             set value(int newValue) => _value = newValue;
           }
           ''';
        // Expect getter and setter signatures
        final expectedOutput = r'''
class GetSet {
  /// The current value.
  int get value;

  /// Set a new value.
  set value(int newValue);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test(
          'should correctly extract class method, getter, and setter signatures',
          () {
        final input = r'''
class MyService {
  /// A regular method.
  void performAction(String input) {
    // implementation
  }

  /// A getter property.
  String get status {
    return "active";
  }

  /// A setter property.
  set newStatus(String s) {
    // implementation
  }

  /// Getter with no explicit type
  get version => "1.0";

  /// Abstract method
  void mustImplement();

  /// External method
  external void nativeCall(int code);
}
''';
        final expectedOutput = r'''
class MyService {
  /// A regular method.
  void performAction(String input);

  /// A getter property.
  String get status;

  /// A setter property.
  set newStatus(String s);

  /// Getter with no explicit type
  get version;

  /// Abstract method
  void mustImplement();

  /// External method
  external void nativeCall(int code);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle various constructor types', () {
        final input = r'''
          class Widget {
            final int id;

            /// Default constructor.
            Widget(this.id);

            /// Named constructor.
            Widget.named(this.id);

            /// Const constructor.
            const Widget.constant(this.id);

            /// Factory constructor.
            factory Widget.fromId(int id) {
              return Widget(id);
            }
          }
          ''';
        // Expect all constructor signatures
        final expectedOutput = r'''
class Widget {
  final int id;

  /// Default constructor.
  Widget(this.id);

  /// Named constructor.
  Widget.named(this.id);

  /// Const constructor.
  const Widget.constant(this.id);

  /// Factory constructor.
  factory Widget.fromId(int id);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Signatures and Details Group

    // =========================================================================
    // Metadata Annotations Group
    // =========================================================================
    group('Metadata Annotations', () {
      test('should preserve common annotations', () {
        final input = r'''
          class Base {
            void method() {}
          }
          class Derived extends Base {
            @override
            void method() {}

            @Deprecated('Use method() instead')
            void oldMethod() {}
          }
          ''';
        // Expect annotations to be kept with the signatures
        final expectedOutput = r'''
class Base {
  void method();
}

class Derived extends Base {
  @override
  void method();

  @Deprecated('Use method() instead')
  void oldMethod();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should preserve multiple and custom annotations', () {
        final input = r'''
          const myAnnotation = Object();

          @myAnnotation
          @Deprecated('Old class')
          class AnnotatedClass {
            @myAnnotation
            final int field;

            AnnotatedClass(this.field);
          }
          ''';
        // Expect all annotations to be kept
        final expectedOutput = r'''
const myAnnotation = Object();

@myAnnotation
@Deprecated('Old class')
class AnnotatedClass {
  @myAnnotation
  final int field;

  AnnotatedClass(this.field);
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should preserve annotations on parameters', () {
        final input = r'''
          const Required = Object();
          void process({@Required String name}) {}
          ''';
        // Expect annotation on parameter to be kept
        final expectedOutput = r'''
const Required = Object();

void process({@Required String name});
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Metadata Annotations Group

    // =========================================================================
    // Ignored Elements Group
    // =========================================================================
    group('Ignored Elements', () {
      test('should ignore directives (import, export, library, part, part of)',
          () {
        // --- CORRECTED input: Removed invalid 'part of' inside class ---
        final input = r'''
         library my_lib;

         import 'dart:async';
         import 'package:meta/meta.dart';

         export 'src/models.dart';
         part 'src/internal_utils.dart'; // Valid top-level directive

         /// This class should be kept.
         class PublicApi {
           // No 'part of' here anymore
           /// A field inside the class.
           int value = 0;
         }

         /// This function should be kept.
         void publicFunction() {}
         ''';

        // Expected output should now be generated correctly without directives
        final expectedOutput = r'''
/// This class should be kept.
class PublicApi {
  /// A field inside the class.
  int value;
}

/// This function should be kept.
void publicFunction();
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should ignore non-doc comments', () {
        final input = r'''
         // This is a single line comment before class.
         /* This is a
            block comment before class. */
         class MyClass {
           // Comment inside class
           int field; /* block comment */

           /* Comment before method */
           void method() {
             // Implementation comment
           }
         }
         ''';
        // Expect only the class structure and public signature, no regular comments
        final expectedOutput = r'''
class MyClass {
  int field;

  void method();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Ignored Elements Group

    // =========================================================================
    // Formatting Group
    // =========================================================================
    group('Formatting', () {
      test('should maintain reasonable spacing between top-level elements', () {
        final input = r'''
         /// First function.
         void func1() {}


         /// Second function.
         void func2() {} // Extra space before this class

         class MyClass {
           /// Method 1.
           void method1() {}


           /// Method 2.
           void method2() {}
         }
         ''';
        // Expect consistent (single) newline spacing controlled by the visitor
        final expectedOutput = r'''
/// First function.
void func1();

/// Second function.
void func2();

class MyClass {
  /// Method 1.
  void method1();

  /// Method 2.
  void method2();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle indentation correctly within declarations', () {
        // --- REVISED input using valid Dart ---
        // Replace nested class with methods and fields
        final input = r'''
         class Outer {
           int outerField;

           /// An inner method.
           void innerMethod(int value) {
              // Some implementation
           }

           /// Another outer method.
           String outerMethod() {
             return 'result';
           }
         } // End Outer
         ''';

        // --- REVISED expectedOutput based on valid input ---
        final expectedOutput = r'''
class Outer {
  int outerField;

  /// An inner method.
  void innerMethod(int value);

  /// Another outer method.
  String outerMethod();
}
''';
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Formatting Group

    // =========================================================================
    // Error Handling Group (DartContentProcessor)
    // =========================================================================
    group('Error Handling (DartContentProcessor)', () {
      test('should return original content on parse error', () {
        // Input with a clear syntax error (missing closing brace)
        final inputWithError = r'''
class MyClass {
  void myMethod() { // Missing closing brace
''';
        // Expect the *original* content back due to the parse error fallback
        expect(processApi(inputWithError), equals(inputWithError));
        // Optionally, check stderr output if logging is implemented and testable
      });

      test('should handle empty input string', () {
        final input = '';
        final expectedOutput = '';
        expect(processApi(input), equals(expectedOutput));
      });

      test('should handle input with only comments and directives', () {
        final input = r'''
// This is a line comment
/* This is a block comment */
/// This is a doc comment, but no declaration follows
library test_lib; // Now before import

import 'dart:io'; // Import after library
''';
        // Expect an empty string as there's no API surface
        final expectedOutput = r'''
'''; // Empty string expected
        expect(processApi(input), equals(expectedOutput));
      });
    }); // End of Error Handling Group
  }); // End of API Extraction Tests group
}
