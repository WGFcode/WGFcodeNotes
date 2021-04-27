//===--- CodeCompletion.h - Routines for code completion --------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IDE_CODECOMPLETION_H
#define SWIFT_IDE_CODECOMPLETION_H

#include "swift/AST/Identifier.h"
#include "swift/Basic/Debug.h"
#include "swift/Basic/LLVM.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/TrailingObjects.h"
#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace swift {
class CodeCompletionCallbacksFactory;
class Decl;
class DeclContext;
class FrontendOptions;
class ModuleDecl;

namespace ide {

class CodeCompletionCache;
class CodeCompletionContext;
class CodeCompletionResultBuilder;
struct RequestedCachedModule;

/// A routine to remove code completion tokens from code completion
/// tests.
///
/// \code
/// code-completion-token:
///     '#^' identifier '^#'
/// \endcode
///
/// \param Input test source code.
/// \param TokenName names the token whose position should be returned in
/// \p CompletionOffset.
/// \param CompletionOffset set to ~0U on error, or to a 0-based byte offset on
/// success.
///
/// \returns test source code without any code completion tokens.
std::string removeCodeCompletionTokens(StringRef Input,
                                       StringRef TokenName,
                                       unsigned *CompletionOffset);

StringRef copyString(llvm::BumpPtrAllocator &Allocator,
                     StringRef Str);

const char *copyCString(llvm::BumpPtrAllocator &Allocator,
                        StringRef Str);

template <typename T>
ArrayRef<T> copyArray(llvm::BumpPtrAllocator &Allocator,
                            ArrayRef<T> Arr) {
  T *Buffer = Allocator.Allocate<T>(Arr.size());
  std::copy(Arr.begin(), Arr.end(), Buffer);
  return llvm::makeArrayRef(Buffer, Arr.size());
}

namespace detail {
class CodeCompletionStringChunk {
  friend class swift::ide::CodeCompletionResultBuilder;

public:
  enum class ChunkKind {
    /// "open", "public", "internal", "fileprivate", or "private".
    AccessControlKeyword,

    /// such as @"available".
    DeclAttrKeyword,

    /// such as "unavailable" etc. for @available.
    DeclAttrParamKeyword,

    /// The "override" keyword.
    OverrideKeyword,

    /// The "throws", "rethrows" and "async" keyword.
    EffectsSpecifierKeyword,

    /// The keyword part of a declaration before the name, like "func".
    DeclIntroducer,

    /// Other generic keyword.
    Keyword,

    /// Other generic attributes.
    Attribute,

    /// Normal text chunk.
    Text,

    /// Base name of the result.
    BaseName,

    /// The first chunk of an optional substring that continues until
    /// \c NestingLevel decreases.
    OptionalBegin,

    /// Punctuation.
    LeftParen,
    RightParen,
    LeftBracket,
    RightBracket,
    LeftAngle,
    RightAngle,
    Dot,
    Ellipsis,
    Comma,
    ExclamationMark,
    QuestionMark,
    Ampersand,
    Equal,
    Whitespace,

    /// The first chunk of a substring that describes the parameter for a
    /// generic type.
    GenericParameterBegin,
    /// Generic type parameter name.
    GenericParameterName,

    /// The first chunk of a substring that describes the parameter for a
    /// function call.
    CallParameterBegin,
    /// Function call parameter name.
    CallParameterName,
    /// Function call parameter internal / local name.  If the parameter has no
    /// formal API name, it can still have a local name which can be useful
    /// for display purposes.
    ///
    /// This chunk should not be inserted into the editor buffer.
    CallParameterInternalName,
    /// A colon between parameter name and value.  Should be inserted in the
    /// editor buffer if the preceding CallParameterName was inserted.
    CallParameterColon,

    /// A colon between parameter name and value. Used in decl attribute.
    DeclAttrParamColon,

    /// Required parameter type.
    CallParameterType,

    /// Parameter type tag for annotated results.
    CallParameterTypeBegin,

    /// System type name.
    TypeIdSystem,

    /// Non-system type name.
    TypeIdUser,

    /// Desugared closure parameter type. This can be used to get the
    /// closure type if CallParameterType is a TypeAliasType.
    CallParameterClosureType,

    /// An expanded closure expression for the value of a parameter, including
    /// the left and right braces and possible signature. The preferred
    /// position to put the cursor after the completion result is inserted
    /// into the editor buffer is between the braces.
    CallParameterClosureExpr,

    /// A placeholder for \c ! or \c ? in a call to a method found by dynamic
    /// lookup.
    ///
    /// The default spelling is \c !, but clients may render it as \c ? if
    /// desired.
    DynamicLookupMethodCallTail,

    /// A placeholder for \c ! or \c ? in a call to an optional method.
    ///
    /// The default spelling is \c !, but clients may render it as \c ? if
    /// desired.
    OptionalMethodCallTail,

    /// Specifies the type of the whole entity that is returned in this code
    /// completion result.  For example, for variable references it is the
    /// variable type, for function calls it is the return type.
    ///
    /// This chunk should not be inserted into the editor buffer.
    TypeAnnotation,

    /// Structured group version of 'TypeAnnotation'.
    /// This grouped chunks should not be inserted into the editor buffer.
    TypeAnnotationBegin,

    /// A brace statement -- left brace and right brace.  The preferred
    /// position to put the cursor after the completion result is inserted
    /// into the editor buffer is between the braces.
    ///
    /// The spelling is always "{}", but clients may choose to insert newline
    /// and indentation in between.
    BraceStmtWithCursor,
  };

  static bool chunkStartsNestedGroup(ChunkKind Kind) {
    return Kind == ChunkKind::CallParameterBegin ||
           Kind == ChunkKind::GenericParameterBegin ||
           Kind == ChunkKind::OptionalBegin ||
           Kind == ChunkKind::CallParameterTypeBegin ||
           Kind == ChunkKind::TypeAnnotationBegin;
  }

  static bool chunkHasText(ChunkKind Kind) {
    return Kind == ChunkKind::AccessControlKeyword ||
           Kind == ChunkKind::OverrideKeyword ||
           Kind == ChunkKind::EffectsSpecifierKeyword ||
           Kind == ChunkKind::DeclAttrKeyword ||
           Kind == ChunkKind::DeclIntroducer ||
           Kind == ChunkKind::Keyword ||
           Kind == ChunkKind::Attribute ||
           Kind == ChunkKind::BaseName ||
           Kind == ChunkKind::Text ||
           Kind == ChunkKind::LeftParen ||
           Kind == ChunkKind::RightParen ||
           Kind == ChunkKind::LeftBracket ||
           Kind == ChunkKind::RightBracket ||
           Kind == ChunkKind::LeftAngle ||
           Kind == ChunkKind::RightAngle ||
           Kind == ChunkKind::Dot ||
           Kind == ChunkKind::Ellipsis ||
           Kind == ChunkKind::Comma ||
           Kind == ChunkKind::ExclamationMark ||
           Kind == ChunkKind::QuestionMark ||
           Kind == ChunkKind::Ampersand ||
           Kind == ChunkKind::Equal ||
           Kind == ChunkKind::Whitespace ||
           Kind == ChunkKind::CallParameterName ||
           Kind == ChunkKind::CallParameterInternalName ||
           Kind == ChunkKind::CallParameterColon ||
           Kind == ChunkKind::DeclAttrParamColon ||
           Kind == ChunkKind::DeclAttrParamKeyword ||
           Kind == ChunkKind::CallParameterType ||
           Kind == ChunkKind::CallParameterClosureType ||
           Kind == ChunkKind::CallParameterClosureExpr ||
           Kind == ChunkKind::GenericParameterName ||
           Kind == ChunkKind::DynamicLookupMethodCallTail ||
           Kind == ChunkKind::OptionalMethodCallTail ||
           Kind == ChunkKind::TypeAnnotation ||
           Kind == ChunkKind::BraceStmtWithCursor ||
           Kind == ChunkKind::TypeIdSystem ||
           Kind == ChunkKind::TypeIdUser;
  }

private:
  unsigned Kind : 8;
  unsigned NestingLevel : 8;

  /// If true, then this chunk is an annotation that is included only
  /// for exposition and may not be inserted in the editor buffer.
  unsigned IsAnnotation : 1;

  StringRef Text;

  CodeCompletionStringChunk(ChunkKind Kind, unsigned NestingLevel, StringRef Text,
                            bool isAnnotation)
      : Kind(unsigned(Kind)), NestingLevel(NestingLevel),
        IsAnnotation(isAnnotation), Text(Text) {
    assert(chunkHasText(Kind));
  }

  CodeCompletionStringChunk(ChunkKind Kind, unsigned NestingLevel,
                            bool isAnnotation)
      : Kind(unsigned(Kind)), NestingLevel(NestingLevel),
        IsAnnotation(isAnnotation) {
    assert(!chunkHasText(Kind));
  }

  void setIsAnnotation() {
    IsAnnotation = 1;
  }

public:
  ChunkKind getKind() const {
    return ChunkKind(Kind);
  }

  bool is(ChunkKind K) const { return getKind() == K; }

  unsigned getNestingLevel() const {
    return NestingLevel;
  }

  bool isAnnotation() const {
    return IsAnnotation;
  }

  bool hasText() const { return chunkHasText(getKind()); }

  StringRef getText() const {
    assert(hasText());
    return Text;
  }

  bool endsPreviousNestedGroup(unsigned GroupNestingLevel) const {
    return NestingLevel < GroupNestingLevel ||
     (NestingLevel == GroupNestingLevel && chunkStartsNestedGroup(getKind()));
  }

  static CodeCompletionStringChunk createWithText(ChunkKind Kind,
                                                  unsigned NestingLevel,
                                                  StringRef Text,
                                                  bool isAnnotation = false) {
    return CodeCompletionStringChunk(Kind, NestingLevel, Text, isAnnotation);
  }

  static CodeCompletionStringChunk createSimple(ChunkKind Kind,
                                                unsigned NestingLevel,
                                                bool isAnnotation = false) {
    return CodeCompletionStringChunk(Kind, NestingLevel, isAnnotation);
  }
};

} // end namespace detail

/// A structured representation of a code completion string.
class alignas(detail::CodeCompletionStringChunk) CodeCompletionString final :
    private llvm::TrailingObjects<CodeCompletionString,
                                  detail::CodeCompletionStringChunk> {
  friend class CodeCompletionResultBuilder;
  friend TrailingObjects;

public:
  using Chunk = detail::CodeCompletionStringChunk;

private:
  unsigned NumChunks : 16;

  CodeCompletionString(ArrayRef<Chunk> Chunks);

public:
  /// Creates a \c CodeCompletionString from a list of \c Chunks.
  ///
  /// \note The caller must ensure any text inside \c Chunks will outlive this
  /// object, typically by storing them inside a \c CodeCompletionResultSink.
  static CodeCompletionString *create(llvm::BumpPtrAllocator &Allocator,
                                      ArrayRef<Chunk> Chunks);

  ArrayRef<Chunk> getChunks() const {
    return {getTrailingObjects<Chunk>(), NumChunks};
  }

  StringRef getFirstTextChunk(bool includeLeadingPunctuation = false) const;
  Optional<unsigned>
  getFirstTextChunkIndex(bool includeLeadingPunctuation = false) const;

  /// Concatenates all text chunks considered part of the name to \p OS.
  void getName(raw_ostream &OS) const;

  /// Print a debug representation of the code completion string to \p OS.
  void print(raw_ostream &OS) const;
  SWIFT_DEBUG_DUMP;
};

/// Describes the origin of the code completion result.
///
/// This enum is ordered from the contexts that are "nearest" to the code
/// completion point to "outside" contexts.
enum class SemanticContextKind {
  /// Used in cases when the concept of semantic context is not applicable.
  None,

  /// This is a highly-likely expression-context-specific completion
  /// result.  This description is intentionally vague: this is a catch-all
  /// category for all heuristics for highly-likely results.
  ///
  /// For example, the name of an overridden superclass member inside a nominal
  /// member function has ExpressionSpecific context:
  /// \code
  ///   class Base {
  ///     init() {}
  ///     init(a: Int) {}
  ///     func foo() {}
  ///     func bar() {}
  ///   }
  ///   class Derived {
  ///     init() {
  ///       super. // init() -- ExpressionSpecific
  ///              // init(a: Int) -- Super
  ///     }
  ///
  ///     func foo() {
  ///       super. // foo() -- ExpressionSpecific
  ///              // bar() -- Super
  ///     }
  ///   }
  /// \endcode
  ExpressionSpecific,

  /// A declaration from the same function.
  Local,

  /// A declaration found in the immediately enclosing nominal decl.
  CurrentNominal,

  /// A declaration found in the superclass of the immediately enclosing
  /// nominal decl.
  Super,

  /// A declaration found in the non-immediately enclosing nominal decl.
  ///
  /// For example, 'Foo' is visible at (1) because of this.
  /// \code
  ///   struct A {
  ///     typealias Foo = Int
  ///     struct B {
  ///       func foo() {
  ///         // (1)
  ///       }
  ///     }
  ///   }
  /// \endcode
  OutsideNominal,

  /// A declaration from the current module.
  CurrentModule,

  /// A declaration imported from other module.
  OtherModule,
};

/// The declaration kind of a code completion result, if it is a declaration.
enum class CodeCompletionDeclKind {
  Module,
  Class,
  Struct,
  Enum,
  EnumElement,
  Protocol,
  AssociatedType,
  TypeAlias,
  GenericTypeParam,
  Constructor,
  Destructor,
  Subscript,
  StaticMethod,
  InstanceMethod,
  PrefixOperatorFunction,
  PostfixOperatorFunction,
  InfixOperatorFunction,
  FreeFunction,
  StaticVar,
  InstanceVar,
  LocalVar,
  GlobalVar,
  PrecedenceGroup,
};

enum class CodeCompletionLiteralKind {
  ArrayLiteral,
  BooleanLiteral,
  ColorLiteral,
  DictionaryLiteral,
  IntegerLiteral,
  ImageLiteral,
  NilLiteral,
  StringLiteral,
  Tuple,
};

enum class CodeCompletionOperatorKind {
  None,
  Unknown,
  Bang,       // !
  NotEq,      // !=
  NotEqEq,    // !==
  Modulo,     // %
  ModuloEq,   // %=
  Amp,        // &
  AmpAmp,     // &&
  AmpStar,    // &*
  AmpPlus,    // &+
  AmpMinus,   // &-
  AmpEq,      // &=
  LParen,     // ( -- not really an operator, but treated as one in some cases.
  Star,       // *
  StarEq,     // *=
  Plus,       // +
  PlusEq,     // +=
  Minus,      // -
  MinusEq,    // -=
  Dot,        // .
  DotDotDot,  // ...
  DotDotLess, // ..<
  Slash,      // /
  SlashEq,    // /=
  Less,       // <
  LessLess,   // <<
  LessLessEq, // <<=
  LessEq,     // <=
  Eq,         // =
  EqEq,       // ==
  EqEqEq,     // ===
  Greater,    // >
  GreaterEq,  // >=
  GreaterGreater,   // >>
  GreaterGreaterEq, // >>=
  QuestionDot,      // ?.
  Caret,            // ^
  CaretEq,          // ^=
  Pipe,             // |
  PipeEq,           // |=
  PipePipe,         // ||
  TildeEq,          // ~=
};

enum class CodeCompletionKeywordKind {
  None,
#define KEYWORD(X) kw_##X,
#define POUND_KEYWORD(X) pound_##X,
#include "swift/Syntax/TokenKinds.def"
};

enum class CompletionKind {
  None,
  Import,
  UnresolvedMember,
  DotExpr,
  StmtOrExpr,
  PostfixExprBeginning,
  PostfixExpr,
  PostfixExprParen,
  KeyPathExprObjC,
  KeyPathExprSwift,
  TypeDeclResultBeginning,
  TypeSimpleBeginning,
  TypeIdentifierWithDot,
  TypeIdentifierWithoutDot,
  CaseStmtKeyword,
  CaseStmtBeginning,
  NominalMemberBeginning,
  AccessorBeginning,
  AttributeBegin,
  AttributeDeclParen,
  EffectsSpecifier,
  PoundAvailablePlatform,
  CallArg,
  LabeledTrailingClosure,
  ReturnStmtExpr,
  YieldStmtExpr,
  ForEachSequence,
  AfterPoundExpr,
  AfterPoundDirective,
  PlatformConditon,
  AfterIfStmtElse,
  GenericRequirement,
  PrecedenceGroup,
  StmtLabel,
};

/// A single code completion result.
class CodeCompletionResult {
  friend class CodeCompletionResultBuilder;

public:
  enum ResultKind {
    Declaration,
    Keyword,
    Pattern,
    Literal,
    BuiltinOperator,
  };

  /// Describes the relationship between the type of the completion results and
  /// the expected type at the code completion position.
  enum ExpectedTypeRelation {
    /// The result does not have a type (e.g. keyword).
    NotApplicable,

    /// The type relation have not been calculated.
    Unknown,

    /// The relationship of the result's type to the expected type is not
    /// invalid, not convertible, and not identical.
    Unrelated,

    /// The result's type is invalid at the expected position.
    Invalid,

    /// The result's type is convertible to the type of the expected.
    Convertible,

    /// The result's type is identical to the type of the expected.
    Identical,
  };

  enum NotRecommendedReason {
    Redundant,
    Deprecated,
    InvalidContext,
    CrossActorReference,
    NoReason,
  };

private:
  unsigned Kind : 3;
  unsigned AssociatedKind : 8;
  unsigned KnownOperatorKind : 6;
  unsigned SemanticContext : 3;
  unsigned NotRecommended : 1;
  unsigned NotRecReason : 3;
  unsigned IsSystem : 1;

  /// The number of bytes to the left of the code completion point that
  /// should be erased first if this completion string is inserted in the
  /// editor buffer.
  unsigned NumBytesToErase : 7;

public:
  static const unsigned MaxNumBytesToErase = 127;

private:
  CodeCompletionString *CompletionString;
  StringRef ModuleName;
  StringRef BriefDocComment;
  ArrayRef<StringRef> AssociatedUSRs;
  ArrayRef<std::pair<StringRef, StringRef>> DocWords;
  unsigned TypeDistance : 3;

public:
  /// Constructs a \c Pattern, \c Keyword or \c BuiltinOperator result.
  ///
  /// \note The caller must ensure \c CodeCompletionString outlives this result.
  CodeCompletionResult(ResultKind Kind, SemanticContextKind SemanticContext,
                       unsigned NumBytesToErase,
                       CodeCompletionString *CompletionString,
                       ExpectedTypeRelation TypeDistance,
                       CodeCompletionOperatorKind KnownOperatorKind =
                           CodeCompletionOperatorKind::None,
                       StringRef BriefDocComment = StringRef())
      : Kind(Kind), KnownOperatorKind(unsigned(KnownOperatorKind)),
        SemanticContext(unsigned(SemanticContext)), NotRecommended(false),
        NotRecReason(NotRecommendedReason::NoReason),
        NumBytesToErase(NumBytesToErase), CompletionString(CompletionString),
        BriefDocComment(BriefDocComment),
        TypeDistance(TypeDistance) {
    assert(Kind != Declaration && "use the other constructor");
    assert(CompletionString);
    if (isOperator() && KnownOperatorKind == CodeCompletionOperatorKind::None)
      this->KnownOperatorKind =
          (unsigned)getCodeCompletionOperatorKind(CompletionString);
    assert(!isOperator() ||
           getOperatorKind() != CodeCompletionOperatorKind::None);
    AssociatedKind = 0;
    IsSystem = 0;
  }

  /// Constructs a \c Keyword result.
  ///
  /// \note The caller must ensure \c CodeCompletionString outlives this result.
  CodeCompletionResult(CodeCompletionKeywordKind Kind,
                       SemanticContextKind SemanticContext,
                       unsigned NumBytesToErase,
                       CodeCompletionString *CompletionString,
                       ExpectedTypeRelation TypeDistance,
                       StringRef BriefDocComment = StringRef())
      : Kind(Keyword), KnownOperatorKind(0),
        SemanticContext(unsigned(SemanticContext)), NotRecommended(false),
        NotRecReason(NotRecommendedReason::NoReason),
        NumBytesToErase(NumBytesToErase), CompletionString(CompletionString),
        BriefDocComment(BriefDocComment), TypeDistance(TypeDistance) {
    assert(CompletionString);
    AssociatedKind = static_cast<unsigned>(Kind);
    IsSystem = 0;
  }

  /// Constructs a \c Literal result.
  ///
  /// \note The caller must ensure \c CodeCompletionString outlives this result.
  CodeCompletionResult(CodeCompletionLiteralKind LiteralKind,
                       SemanticContextKind SemanticContext,
                       unsigned NumBytesToErase,
                       CodeCompletionString *CompletionString,
                       ExpectedTypeRelation TypeDistance)
      : Kind(Literal), KnownOperatorKind(0),
        SemanticContext(unsigned(SemanticContext)), NotRecommended(false),
        NotRecReason(NotRecommendedReason::NoReason),
        NumBytesToErase(NumBytesToErase), CompletionString(CompletionString),
        TypeDistance(TypeDistance) {
    AssociatedKind = static_cast<unsigned>(LiteralKind);
    IsSystem = 0;
    assert(CompletionString);
  }

  /// Constructs a \c Declaration result.
  ///
  /// \note The caller must ensure \c CodeCompletionString and any StringRef
  /// arguments outlive this result, typically by storing them in the same
  /// \c CodeCompletionResultSink as the result itself.
  CodeCompletionResult(SemanticContextKind SemanticContext,
                       unsigned NumBytesToErase,
                       CodeCompletionString *CompletionString,
                       const Decl *AssociatedDecl, StringRef ModuleName,
                       bool NotRecommended,
                       CodeCompletionResult::NotRecommendedReason NotRecReason,
                       StringRef BriefDocComment,
                       ArrayRef<StringRef> AssociatedUSRs,
                       ArrayRef<std::pair<StringRef, StringRef>> DocWords,
                       enum ExpectedTypeRelation TypeDistance)
      : Kind(ResultKind::Declaration), KnownOperatorKind(0),
        SemanticContext(unsigned(SemanticContext)),
        NotRecommended(NotRecommended), NotRecReason(NotRecReason),
        NumBytesToErase(NumBytesToErase), CompletionString(CompletionString),
        ModuleName(ModuleName), BriefDocComment(BriefDocComment),
        AssociatedUSRs(AssociatedUSRs), DocWords(DocWords),
        TypeDistance(TypeDistance) {
    assert(AssociatedDecl && "should have a decl");
    AssociatedKind = unsigned(getCodeCompletionDeclKind(AssociatedDecl));
    IsSystem = getDeclIsSystem(AssociatedDecl);
    assert(CompletionString);
    if (isOperator())
      KnownOperatorKind =
          (unsigned)getCodeCompletionOperatorKind(CompletionString);
    assert(!isOperator() ||
           getOperatorKind() != CodeCompletionOperatorKind::None);
  }

  // FIXME:
  CodeCompletionResult(SemanticContextKind SemanticContext,
                       unsigned NumBytesToErase,
                       CodeCompletionString *CompletionString,
                       CodeCompletionDeclKind DeclKind, bool IsSystem,
                       StringRef ModuleName, bool NotRecommended,
                       CodeCompletionResult::NotRecommendedReason NotRecReason,
                       StringRef BriefDocComment,
                       ArrayRef<StringRef> AssociatedUSRs,
                       ArrayRef<std::pair<StringRef, StringRef>> DocWords,
                       ExpectedTypeRelation TypeDistance,
                       CodeCompletionOperatorKind KnownOperatorKind)
      : Kind(ResultKind::Declaration),
        KnownOperatorKind(unsigned(KnownOperatorKind)),
        SemanticContext(unsigned(SemanticContext)),
        NotRecommended(NotRecommended), NotRecReason(NotRecReason),
        IsSystem(IsSystem), NumBytesToErase(NumBytesToErase),
        CompletionString(CompletionString), ModuleName(ModuleName),
        BriefDocComment(BriefDocComment), AssociatedUSRs(AssociatedUSRs),
        DocWords(DocWords), TypeDistance(TypeDistance) {
    AssociatedKind = static_cast<unsigned>(DeclKind);
    assert(CompletionString);
    assert(!isOperator() ||
           getOperatorKind() != CodeCompletionOperatorKind::None);
  }

  ResultKind getKind() const { return static_cast<ResultKind>(Kind); }

  CodeCompletionDeclKind getAssociatedDeclKind() const {
    assert(getKind() == Declaration);
    return static_cast<CodeCompletionDeclKind>(AssociatedKind);
  }

  CodeCompletionLiteralKind getLiteralKind() const {
    assert(getKind() == Literal);
    return static_cast<CodeCompletionLiteralKind>(AssociatedKind);
  }

  CodeCompletionKeywordKind getKeywordKind() const {
    assert(getKind() == Keyword);
    return static_cast<CodeCompletionKeywordKind>(AssociatedKind);
  }

  bool isOperator() const {
    if (getKind() != Declaration)
      return getKind() == BuiltinOperator;
    switch (getAssociatedDeclKind()) {
    case CodeCompletionDeclKind::PrefixOperatorFunction:
    case CodeCompletionDeclKind::PostfixOperatorFunction:
    case CodeCompletionDeclKind::InfixOperatorFunction:
      return true;
    default:
      return false;
    }
  }

  CodeCompletionOperatorKind getOperatorKind() const {
    assert(isOperator());
    return static_cast<CodeCompletionOperatorKind>(KnownOperatorKind);
  }

  bool isSystem() const {
    return static_cast<bool>(IsSystem);
  }

  ExpectedTypeRelation getExpectedTypeRelation() const {
    return static_cast<ExpectedTypeRelation>(TypeDistance);
  }

  NotRecommendedReason getNotRecommendedReason() const {
    return static_cast<NotRecommendedReason>(NotRecReason);
  }

  SemanticContextKind getSemanticContext() const {
    return static_cast<SemanticContextKind>(SemanticContext);
  }

  bool isNotRecommended() const {
    return NotRecommended;
  }

  unsigned getNumBytesToErase() const {
    return NumBytesToErase;
  }

  CodeCompletionString *getCompletionString() const {
    return CompletionString;
  }

  StringRef getModuleName() const { return ModuleName; }

  StringRef getBriefDocComment() const {
    return BriefDocComment;
  }

  ArrayRef<StringRef> getAssociatedUSRs() const {
    return AssociatedUSRs;
  }

  ArrayRef<std::pair<StringRef, StringRef>> getDeclKeywords() const {
    return DocWords;
  }

  /// Print a debug representation of the code completion result to \p OS.
  void printPrefix(raw_ostream &OS) const;
  SWIFT_DEBUG_DUMP;

  static CodeCompletionDeclKind getCodeCompletionDeclKind(const Decl *D);
  static CodeCompletionOperatorKind
  getCodeCompletionOperatorKind(StringRef name);
  static CodeCompletionOperatorKind
  getCodeCompletionOperatorKind(CodeCompletionString *str);
  static bool getDeclIsSystem(const Decl *D);
};

struct CodeCompletionResultSink {
  using AllocatorPtr = std::shared_ptr<llvm::BumpPtrAllocator>;

  /// The allocator used to allocate results "native" to this sink.
  AllocatorPtr Allocator;

  /// Allocators that keep alive "foreign" results imported into this sink from
  /// other sinks.
  std::vector<AllocatorPtr> ForeignAllocators;

  /// Whether to annotate the results with XML.
  bool annotateResult = false;

  std::vector<CodeCompletionResult *> Results;

  /// A single-element cache for module names stored in Allocator, keyed by a
  /// clang::Module * or swift::ModuleDecl *.
  std::pair<void *, StringRef> LastModule;

  CodeCompletionResultSink()
      : Allocator(std::make_shared<llvm::BumpPtrAllocator>()) {}
};

/// A utility for calculating the import depth of a given module. Direct imports
/// have depth 1, imports of those modules have depth 2, etc.
///
/// Special modules such as Playground auxiliary sources are considered depth
/// 0.
class ImportDepth {
  llvm::StringMap<uint8_t> depths;

public:
  ImportDepth() = default;
  ImportDepth(ASTContext &context, const FrontendOptions &frontendOptions);

  Optional<uint8_t> lookup(StringRef module) {
    auto I = depths.find(module);
    if (I == depths.end())
      return None;
    return I->getValue();
  }
};

class CodeCompletionContext {
  friend class CodeCompletionResultBuilder;

  /// A set of current completion results, not yet delivered to the
  /// consumer.
  CodeCompletionResultSink CurrentResults;

public:
  CodeCompletionCache &Cache;
  CompletionKind CodeCompletionKind = CompletionKind::None;

  enum class TypeContextKind {
    /// There is no known contextual type. All types are equally good.
    None,

    /// There is a contextual type from a single-expression closure/function
    /// body. The context is a hint, and enables unresolved member completion,
    /// but should not hide any results.
    SingleExpressionBody,

    /// There are known contextual types, or there aren't but a nonvoid type is expected.
    Required,
  };

  TypeContextKind typeContextKind = TypeContextKind::None;

  /// Whether there may be members that can use implicit member syntax,
  /// e.g. `x = .foo`.
  bool MayUseImplicitMemberExpr = false;

  /// Flag to indicate that the completion is happening reusing ASTContext
  /// from the previous completion.
  /// NOTE: Do not use this to change the behavior. This is only for debugging.
  bool ReusingASTContext = false;

  CodeCompletionContext(CodeCompletionCache &Cache)
      : Cache(Cache) {}

  void setAnnotateResult(bool flag) { CurrentResults.annotateResult = flag; }
  bool getAnnotateResult() { return CurrentResults.annotateResult; }

  /// Allocate a string owned by the code completion context.
  StringRef copyString(StringRef Str);

  /// Return current code completion results.
  MutableArrayRef<CodeCompletionResult *> takeResults();

  /// Sort code completion results in an implementation-defined order
  /// in place.
  static void sortCompletionResults(
      MutableArrayRef<CodeCompletionResult *> Results);

  CodeCompletionResultSink &getResultSink() {
    return CurrentResults;
  }
};

/// An abstract base class for consumers of code completion results.
/// \see \c SimpleCachingCodeCompletionConsumer.
class CodeCompletionConsumer {
public:
  virtual ~CodeCompletionConsumer() {}
  virtual void
  handleResultsAndModules(CodeCompletionContext &context,
                          ArrayRef<RequestedCachedModule> requestedModules,
                          DeclContext *DCForModules) = 0;
};

/// A simplified code completion consumer interface that clients can use to get
/// CodeCompletionResults with automatic caching of top-level completions from
/// imported modules.
struct SimpleCachingCodeCompletionConsumer : public CodeCompletionConsumer {

  // Implement the CodeCompletionConsumer interface.
  void handleResultsAndModules(CodeCompletionContext &context,
                               ArrayRef<RequestedCachedModule> requestedModules,
                               DeclContext *DCForModules) override;

  /// Clients should override this method to receive \p Results.
  virtual void handleResults(
      MutableArrayRef<CodeCompletionResult *> Results) = 0;
};

/// A code completion result consumer that prints the results to a
/// \c raw_ostream.
class PrintingCodeCompletionConsumer
    : public SimpleCachingCodeCompletionConsumer {
  llvm::raw_ostream &OS;
  bool IncludeKeywords;
  bool IncludeComments;
  bool PrintAnnotatedDescription;

public:
 PrintingCodeCompletionConsumer(llvm::raw_ostream &OS,
                                bool IncludeKeywords = true,
                                bool IncludeComments = true,
                                bool PrintAnnotatedDescription = false)
     : OS(OS),
       IncludeKeywords(IncludeKeywords),
       IncludeComments(IncludeComments),
       PrintAnnotatedDescription(PrintAnnotatedDescription) {}

 void handleResults(MutableArrayRef<CodeCompletionResult *> Results) override;
};

/// Create a factory for code completion callbacks.
CodeCompletionCallbacksFactory *
makeCodeCompletionCallbacksFactory(CodeCompletionContext &CompletionContext,
                                   CodeCompletionConsumer &Consumer);

/// Lookup the top-level code completions from \p module and store them in
/// \p targetSink.
///
/// Results are looked up as if in \p currDeclContext, which may be null.
void lookupCodeCompletionResultsFromModule(CodeCompletionResultSink &targetSink,
                                           const ModuleDecl *module,
                                           ArrayRef<std::string> accessPath,
                                           bool needLeadingDot,
                                           const DeclContext *currDeclContext);

/// Copy code completion results from \p sourceSink to \p targetSink, possibly
/// restricting by \p onlyTypes.
void copyCodeCompletionResults(CodeCompletionResultSink &targetSink,
                               CodeCompletionResultSink &sourceSink,
                               bool onlyTypes,
                               bool onlyPrecedenceGroups);

} // end namespace ide
} // end namespace swift

namespace llvm {
template <> struct DenseMapInfo<swift::ide::CodeCompletionKeywordKind> {
  using Kind = swift::ide::CodeCompletionKeywordKind;
  static Kind getEmptyKey() { return Kind(~0u); }
  static Kind getTombstoneKey() { return Kind(~1u); }
  static unsigned getHashValue(const Kind &Val) { return unsigned(Val); }
  static bool isEqual(const Kind &LHS, const Kind &RHS) { return LHS == RHS; }
};
template <> struct DenseMapInfo<swift::ide::CodeCompletionLiteralKind> {
  using Kind = swift::ide::CodeCompletionLiteralKind;
  static Kind getEmptyKey() { return Kind(~0u); }
  static Kind getTombstoneKey() { return Kind(~1u); }
  static unsigned getHashValue(const Kind &Val) { return unsigned(Val); }
  static bool isEqual(const Kind &LHS, const Kind &RHS) { return LHS == RHS; }
};
template <> struct DenseMapInfo<swift::ide::CodeCompletionDeclKind> {
  using Kind = swift::ide::CodeCompletionDeclKind;
  static Kind getEmptyKey() { return Kind(~0u); }
  static Kind getTombstoneKey() { return Kind(~1u); }
  static unsigned getHashValue(const Kind &Val) { return unsigned(Val); }
  static bool isEqual(const Kind &LHS, const Kind &RHS) { return LHS == RHS; }
};
}

#endif // SWIFT_IDE_CODECOMPLETION_H
