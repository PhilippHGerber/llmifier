// lib/src/processing/api_extractor_visitor.dart (Corrected v6 - Restore Comment Tokens)

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class ApiExtractorVisitor extends SimpleAstVisitor<void> {
  final StringBuffer _buffer = StringBuffer();
  int _indentationLevel = 0;
  bool _isFirstMember = true; // Tracks if we need a newline before writing

  final String _sourceContent;

  ApiExtractorVisitor(this._sourceContent);

  StringBuffer get apiOutput => _buffer;

  // --- Helper Methods ---
  bool _isPublic(String? name) {
    if (name == null) return true;
    return !name.startsWith('_');
  }

  void _writeln(String text) {
    // Write the line with current indentation
    _buffer.writeln("${_indent()}$text");
    // Mark that we wrote something, so the next element might need a newline
    _isFirstMember = false;
  }

  void _newLineMaybe() {
    // Add separation if needed before the next element
    if (!_isFirstMember && //
        _buffer.isNotEmpty &&
        !_buffer.toString().endsWith('\n\n')) {
      _buffer.writeln();
    }
    _isFirstMember = true; // Reset before potential write
  }

  String _indent() {
    return '  ' * _indentationLevel;
  }

  // Write documentation if it exists, managing spacing.
  void _writeDocumentation(AnnotatedNode node) {
    Comment? comment = node.documentationComment;
    if (comment != null) {
      Token? token = comment.tokens.first;
      while (token != null) {
        // Write the token's lexeme directly, trim only trailing whitespace
        _writeln(token.lexeme.trimRight());
        if (token == comment.tokens.last) break;
        token = token.next;
      }
      // _isFirstMember is set to false by the last _writeln call.
    }
  }

  String _getSource(int startOffset, int endOffset) {
    if (startOffset < 0 || //
        endOffset > _sourceContent.length ||
        startOffset > endOffset) {
      return '/* Error: Invalid source range ($startOffset..$endOffset) */';
    }
    try {
      // Trim only at the end, preserve leading indentation fetched by offsets
      return _sourceContent.substring(startOffset, endOffset).trimRight();
    } catch (e) {
      return '/* Error retrieving source: $e */';
    }
  }

  bool _isMemberContainer(AstNode? node) {
    return node is ClassDeclaration ||
        node is MixinDeclaration ||
        node is ExtensionDeclaration ||
        node is EnumDeclaration ||
        node is ExtensionTypeDeclaration;
  }

  // --- Visitor Methods (Using node.firstTokenAfterCommentAndMetadata) ---
  // (These methods remain the same as v5, ensuring they call the
  //  now-corrected _writeDocumentation and use firstTokenAfterCommentAndMetadata)

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _isFirstMember = true;
    for (var declaration in node.declarations) {
      declaration.accept(this);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.leftBracket.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);

      _indentationLevel++;
      _isFirstMember = true;
      for (var member in node.members) {
        member.accept(this);
      }
      _indentationLevel--;
      _isFirstMember = false;
      _writeln("}");
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (_isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.leftBracket.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);

      _indentationLevel++;
      _isFirstMember = true;
      for (var member in node.members) {
        member.accept(this);
      }
      _indentationLevel--;
      _isFirstMember = false;
      _writeln("}");
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final bool isPublic = _isPublic(node.name?.lexeme);
    if (isPublic) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.leftBracket.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);

      _indentationLevel++;
      _isFirstMember = true;
      for (var member in node.members) {
        member.accept(this);
      }
      _indentationLevel--;
      _isFirstMember = false;
      _writeln("}");
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (_isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.leftBracket.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);

      _indentationLevel++;
      _isFirstMember = true;
      for (var member in node.members) {
        member.accept(this);
      }
      _indentationLevel--;
      _isFirstMember = false;
      _writeln("}");
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (_isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.leftBracket.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);

      _indentationLevel++;
      _isFirstMember = true;
      for (var constant in node.constants) {
        constant.accept(this);
      }
      for (var member in node.members) {
        member.accept(this);
      }
      _indentationLevel--;
      _isFirstMember = false;
      _writeln("}");
    }
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _writeDocumentation(node);
    for (final annotation in node.metadata) {
      final String annotationSource = _getSource(
        annotation.offset,
        annotation.end,
      );
      _writeln(annotationSource);
    }
    final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
    final int endOffset = node.end;
    final String constSignature = _getSource(startOffset, endOffset);
    final String lineToWrite = constSignature.trimRight().endsWith(',') //
        ? constSignature
        : "$constSignature,";
    _writeln(lineToWrite); // Write the constant line
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit && _isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;

      final int endOffset;
      // Check if it's a getter (no parameters) or a regular function/setter
      if (node.isGetter || node.functionExpression.parameters == null) {
        // For GETTERS: Signature ends before the body (e.g., before '=>' or '{').
        endOffset = node.functionExpression.body.offset;
      } else {
        // For regular functions or SETTERS: Signature ends after the parameter list.
        endOffset = node.functionExpression.parameters!.rightParenthesis.end;
      }

      final String signature = _getSource(startOffset, endOffset).trimRight();

      _writeln("$signature;");
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isMemberContainer(node.parent) && _isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset;

      if (node.isGetter) {
        // Getter: Type get name; Signature ends before body.
        endOffset = node.body.offset;
      } else if (node.isSetter) {
        // Setter: set name(Type val); Signature ends after parameters.
        endOffset = node.parameters!.rightParenthesis.end;
      } else {
        // Regular method, abstract method, or external method
        if (node.parameters != null) {
          // Method with parameters (even if empty like "method()")
          endOffset = node.parameters!.rightParenthesis.end;
        } else {
          // Method without a parameter list node in AST.
          // This can be an abstract method like "Type m();" or an external method like "external Type m();"
          // or a getter (which is handled above).
          // For abstract/external methods, node.body.offset often points to the semicolon.
          // If the semicolon is part of the body token, we might get it. If not, we add it.
          endOffset = node.body.offset;
        }
      }

      String signature = _getSource(startOffset, endOffset).trimRight();

      // For API view, all method declarations (regular, abstract, external, getters, setters)
      // should end with a semicolon.
      // Getters and setters are handled by their specific offset logic ending before the body,
      // so they will naturally need a semicolon.
      // Regular methods, abstract methods, and external methods also need one.
      if (!signature.endsWith(';')) {
        signature = '$signature;';
      }

      _writeln(signature);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Check if the parent is a type that can contain constructors
    final parentDeclaration = node.parent; // Get the parent node
    if (parentDeclaration is ClassDeclaration ||
        parentDeclaration is MixinDeclaration ||
        parentDeclaration is EnumDeclaration ||
        parentDeclaration is ExtensionTypeDeclaration) {
      // Determine if the constructor itself or its container is public
      bool isPublicContext = false;

      // Get the PARENT declaration's name TOKEN
      Token? parentNameToken;
      if (parentDeclaration is ClassDeclaration) {
        parentNameToken = parentDeclaration.name;
      } else if (parentDeclaration is MixinDeclaration) {
        parentNameToken = parentDeclaration.name;
      } else if (parentDeclaration is EnumDeclaration) {
        parentNameToken = parentDeclaration.name;
      } else if (parentDeclaration is ExtensionTypeDeclaration) {
        parentNameToken = parentDeclaration.name;
      }

      // Check if the PARENT declaration (Class, Mixin, Enum, ExtType) is public using the Token's lexeme
      if (_isPublic(parentNameToken?.lexeme)) {
        // Now check the constructor name itself (SimpleIdentifier?, also has lexeme)
        // node.name is the SimpleIdentifier? for named constructors, null for default
        if (node.name == null || _isPublic(node.name?.lexeme)) {
          isPublicContext = true;
        }
      }

      if (isPublicContext) {
        // Existing logic for writing documentation and signature
        _newLineMaybe();
        _writeDocumentation(node);
        for (final annotation in node.metadata) {
          final String annotationSource = _getSource(
            annotation.offset,
            annotation.end,
          );
          _writeln(annotationSource);
        }
        final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
        final int endOffset = node.parameters.rightParenthesis.end;
        final String signature = _getSource(startOffset, endOffset);

        // Always add semicolon for non-external constructors in API view
        if (node.externalKeyword == null) {
          _writeln("$signature;");
        } else {
          _writeln(signature); // Keep external keyword, no semicolon needed
        }
      }
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // Only process if inside a relevant container (Class, Mixin, Enum, ExtType)
    if (_isMemberContainer(node.parent)) {
      // Check if *at least one* of the declared variables in this statement is public
      final variables = node.fields.variables; // Get the list of variable nodes
      final bool hasPublicField = variables.any((v) => _isPublic(v.name.lexeme));

      if (hasPublicField) {
        _writeDocumentation(node);
        for (final annotation in node.metadata) {
          final String annotationSource = _getSource(
            annotation.offset,
            annotation.end,
          );
          _writeln(annotationSource);
        }
        // Check modifiers
        final bool isStatic = node.isStatic;
        final VariableDeclarationList fieldList = node.fields; // Cache for easier access
        final bool isConst = fieldList.keyword?.type == Keyword.CONST;
        final bool isFinal = fieldList.keyword?.type == Keyword.FINAL;

        // --- LATE CHECK ---
        // Check if the token *before* the main keyword (or type if no keyword) is 'late'
        // This is heuristic - assumes 'late' comes right before 'final'/'var'/type
        Token? tokenBeforeKeywordOrType = fieldList.keyword?.previous ?? fieldList.type?.beginToken.previous;
        final bool isLate = tokenBeforeKeywordOrType?.type == Keyword.LATE;

        // Special handling for static const
        if (isStatic && isConst) {
          final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
          final int endOffset = node.semicolon.end;
          final String signature = _getSource(startOffset, endOffset);
          _writeln(signature);
        } else {
          // Build signature manually for other fields
          final buffer = StringBuffer();

          // Add modifiers in canonical order
          if (isLate) buffer.write('late ');
          if (isFinal) buffer.write('final ');
          // isConst only relevant if static (handled above)
          if (isStatic) buffer.write('static ');

          // Type annotation
          final typeAnnotation = fieldList.type;
          if (typeAnnotation != null) {
            buffer.write(
              '${_getSource(typeAnnotation.offset, typeAnnotation.end)} ',
            );
          } else if (fieldList.keyword?.type == Keyword.VAR) {
            // Keep 'var' if explicitly used and no type
            buffer.write('var ');
          }

          // Public Variable names
          bool firstPublicVarWritten = true;
          for (var variable in variables) {
            if (_isPublic(variable.name.lexeme)) {
              if (!firstPublicVarWritten) buffer.write(', ');
              buffer.write(variable.name.lexeme);
              firstPublicVarWritten = false;
            }
          }

          // Write line only if public vars were found
          if (!firstPublicVarWritten) {
            buffer.write(';');
            _writeln(buffer.toString());
          }
        }
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.parent is CompilationUnit) {
      final bool hasPublicVar = node.variables.variables.any(
        (v) => _isPublic(v.name.lexeme),
      );
      if (hasPublicVar) {
        _newLineMaybe();
        _writeDocumentation(node);
        for (final annotation in node.metadata) {
          final String annotationSource = _getSource(
            annotation.offset,
            annotation.end,
          );
          _writeln(annotationSource);
        }
        final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
        final int endOffset = node.semicolon.end;
        final String signature = _getSource(startOffset, endOffset);
        _writeln(signature);
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (node.parent is CompilationUnit && _isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.semicolon.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.parent is CompilationUnit && _isPublic(node.name.lexeme)) {
      _newLineMaybe();
      _writeDocumentation(node);
      for (final annotation in node.metadata) {
        final String annotationSource = _getSource(
          annotation.offset,
          annotation.end,
        );
        _writeln(annotationSource);
      }
      final int startOffset = node.firstTokenAfterCommentAndMetadata.offset;
      final int endOffset = node.semicolon.end;
      final String signature = _getSource(startOffset, endOffset);
      _writeln(signature);
    }
  }

  // --- Ignore/Skip Methods ---
  // (Remain the same)
  @override
  void visitImportDirective(ImportDirective node) {}
  @override
  void visitExportDirective(ExportDirective node) {}
  @override
  void visitPartDirective(PartDirective node) {}
  @override
  void visitPartOfDirective(PartOfDirective node) {}
}
