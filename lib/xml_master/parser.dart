import 'package:sample/xml_master/xml_document.dart';
import 'package:sample/xml_master/xml_node.dart';

import './exception.dart';

/// [Symbol] represents symbols used in sample XML
enum Symbol {
  /// A '<' smaller than symbol representing opening tag's beginning
  begTag,

  /// A '</' symbol representing closing tag's beginning
  endTag,

  /// '>' symbol
  closeTag,

  /// '/>' symbol
  selfCloseTag,

  /// **"** symbol
  double_quots,

  /// **'** symbol
  single_quots,

  /// '\n' character
  lineBreak,

  /// Regular space ' ' in tags
  space,

  /// Any other string
  stringtext,

  /// "<?" representing either instruction tag or document description tag start
  instruction,

  /// "?>" representing either instruction tag or document description tag start
  instructionEnd,

  /// The "=" assignment operator
  assignment,

  /// '\t' character
  tabSpace,
}

/// [Text] represents text from outside of tags
class Text {
  /// The [String] this [Text] holds
  final String text;

  /// [Text] represents text from outside of tags
  Text(this.text);

  /// Converts [Text] to [String]
  String toText() => text;
  @override

  /// [Text] to [String] with added double quotes
  String toString() => '"$text"';
}

/// This represents text used under tags as tagname or tag-property
class NamespaceWord {
  /// The [String] this holds
  final String tagWord;
  bool _isTagname = true;

  bool get isTagname => _isTagname;

  set isTagname(bool isTagname) {
    _isTagname = isTagname;
  }

  /// [NamespaceWord] of a tag which is a property name or tagname
  NamespaceWord(this.tagWord) {
    // check if tagword uses legal characters
    if (!_isValidTagword(tagWord)) {
      throw IllegalTagwordException(tagWord);
    }
  }

  /// [NamespaceWord] to String without quotes
  String toText() => tagWord;
  @override

  /// [NamespaceWord] to String with single quotes
  String toString() => "'$tagWord'";

  /// Check if [String] is a valid [NamespaceWord]
  static bool _isValidTagword(String text) {
    // Characters which shouldn't be in tagwords
    List<String> notAllowed;
    notAllowed = [
      '!',
      '\"',
      '#',
      '\$',
      '%',
      '&',
      "'",
      '(',
      ')',
      '*',
      '+',
      '/',
      ';',
      '<',
      '=',
      '>',
      '?',
      '@',
      '[',
      '\\',
      ']',
      '^',
      '`',
      '{',
      '|',
      '}',
      '~',
      ' ',
    ];
    // If start of tagname is '-' or '.' then it is illegal
    if ((text[0] ?? '') == '-' || (text[0] ?? '') == '.') {
      return false;
    }
    // If start of tagname is a number then it is illegal
    try {
      var number = double.parse(text[0]);
      return false;
    } on FormatException {
      // ignoring because first character is NaN
    }

    // check if any character used in tagword is illegal
    for (var syms in notAllowed) {
      if (text.contains(syms)) {
        return false;
      }
    }
    return true;
  }
}

/// [XmlParser] creates an [XmlDocument] from [String] in xml format
class XmlParser {
  List tokens;
  String text;

  XmlParser(this.text) {
    // gets a valid list of tokens from string text.
    tokens = XmlLexer(text).getTokens;
  }

  /// [XmlParser] parses and converts to [XmlDocument] based on token context
  XmlDocument parse() {
    var document = XmlDocument(
      '1.0',
      'UTF-8',
    );
    XmlNode targetNode;
    var documentDeclarationCompleted = false;
    var skipEndTag = false;
    Map<String, dynamic> attribute_map;
    String lastAttribute;
    var unResolvedTags = [];
    // expect tokens
    var expectInstructions = false;
    var expectAttributeDefinition = false;
    var expectAttributeValue = false;
    var underEndingTag = false;
    var currentNamespace = '';
    var afterClosingTag = false;

    // space
    targetNode = document.root;
    attribute_map = {};

    for (var i = 0; i < tokens.length; i++) {
      // print(
      //     'At $i/${tokens.length - 1}, [${i - 1 >= 0 ? tokens[i - 1] : null} ${tokens[i]} ${i + 1 < tokens.length ? tokens[i + 1] : null}]');
      var target = tokens[i];
      // var target_next = i + 1 < tokens.length ? tokens[i + 1] : null;
      if (target is Symbol) {
        switch (target) {
          case Symbol.begTag:
            // Create a new Node and pass the previous one as it's parent
            // Add current node to the children list of it's parent
            if (afterClosingTag) {
              // It's sibling to previous node so this new one will have the same parent
              targetNode = XmlNode.create(targetNode.parent);
              targetNode.parent.addChild(targetNode);
              afterClosingTag = false;
              continue;
            }
            // It's a new xml node
            targetNode = XmlNode.create(targetNode);
            document.root ??= targetNode;
            if (targetNode.parent != null) {
              targetNode.parent.addChild(targetNode);
            }

            /// TODO print(targetNode);
            break;
          case Symbol.instruction:
            if (!documentDeclarationCompleted) {
              expectInstructions = true;
              break;
            }
            throw UnexpectedTokenException('Other instructions not supported');
          case Symbol.instructionEnd:
            if (!documentDeclarationCompleted) {
              documentDeclarationCompleted = true;
              attribute_map = {};
            }
            expectAttributeDefinition = false;
            expectInstructions = false;
            break;
          case Symbol.closeTag:
            if (!underEndingTag) {
              currentNamespace = targetNode.tagName;
              targetNode.attributes.addAll(attribute_map);
              attribute_map = {};
            } else {
              afterClosingTag = true;
            }
            // TODO
            // print('${targetNode} at $i');
            // print(
            //     '${i - 1 >= 0 ? tokens[i - 1] : null} ${tokens[i]} ${i + 1 < tokens.length ? tokens[i + 1] : null}');
            expectAttributeDefinition = false;
            underEndingTag = false;
            break;
          case Symbol.endTag:
            if (afterClosingTag) {
              // If previous was a node's ending tag, so the current endTag belongs to the previous node's parent
              targetNode = targetNode.parent;
              afterClosingTag = false;
            }
            underEndingTag = true;
            break;
          case Symbol.selfCloseTag:
            expectAttributeDefinition = false;
            break;
          default:
        }
      } else if (target is NamespaceWord) {
        if (!documentDeclarationCompleted) {
          // This is the type of document
          if (!expectAttributeDefinition) {
            // namespace element is tagname
            if (target.tagWord != 'xml') {
              throw UnexpectedTokenException(
                  'Only xml type document is supported');
            }
            // Document already defined as type xml
            expectAttributeDefinition = true;
          } else {
            // It's attribute definition (not tagname)
            if (!expectAttributeValue) {
              // attribute name
              switch (target.tagWord) {
                case 'version':
                  attribute_map['version'] = '';
                  break;
                case 'encoding':
                  attribute_map['encoding'] = '';
                  break;
                default:
              }
              expectAttributeValue = true;
            } else {
              // attribute value
              if (attribute_map['version']?.isEmpty ?? true) {
                attribute_map['version'] = target.tagWord;
              } else if (attribute_map['encoding']?.isEmpty ?? true) {
                attribute_map['encoding'] = target.tagWord;
              } else {
                throw XmlParsingException();
              }
            }
          }
        }
        if (!expectAttributeDefinition) {
          // namespace element is tagname
          if (underEndingTag) {
            if (targetNode.tagName != target.tagWord) {
              throw IllegalTagwordException('The Tagnames are not matching');
            }
          } else {
            targetNode.tagName = target.tagWord;
            expectAttributeDefinition = true;
          }
        } else {
          // It's attribute definition (not tagname)
          if (!expectAttributeValue) {
            // attribute name
            lastAttribute = target.tagWord;
            expectAttributeValue = true;
          } else {
            // Value for attribute
            attribute_map[lastAttribute] = target.tagWord;
            lastAttribute = null;
            expectAttributeValue = false;
          }
        }
      } else if (target is Text) {
        if (!documentDeclarationCompleted) {
          // This is the type of document
          if (expectAttributeDefinition) {
            // It's attribute definition (not tagname)
            if (expectAttributeValue) {
              // attribute value
              if (attribute_map['version']?.isEmpty ?? true) {
                attribute_map['version'] = target.text;
              } else if (attribute_map['encoding']?.isEmpty ?? true) {
                attribute_map['encoding'] = target.text;
              } else {
                throw XmlParsingException();
              }
            }
          }
        } else if (expectAttributeDefinition) {
          // It's attribute definition (not tagname)
          if (expectAttributeValue) {
            // Value for attribute
            attribute_map[lastAttribute] = target.text;
            lastAttribute = null;
            expectAttributeValue = false;
          }
        } else {
          // These are regular text
          targetNode.text = target.text;
        }
      }
    }
    return document;
  }
}

class XmlLexer {
  /// The regular String passed to this [XmlParser]
  final String text;
  // value of index at
  int _i = 0;
  // Target character
  String _target;
  // The character after [_target]
  String _target_next;
  // Under sequence of value for a tag's property
  bool _valueSeq;
  // Under sequence of a tagname or tag property
  bool _tagWordSeq;
  // Under sequence of text outside of the tag
  bool _normalTextSeq;
  // List of tokens
  List<dynamic> tokens;

  List get getTokens => tokens;

  XmlLexer(this.text) {
    // Creating tokens
    lexer();
    // Parsing to XML tree
    // parser();
  }

  /// [lexer] adds more meaning to tokens
  void lexer() {
    tokens = [];
    _valueSeq = false;
    _tagWordSeq = false;
    _normalTextSeq = false;
    // Stores String temporarily
    String cacheString;
    cacheString = '';
    // Started lexing in an iterator fashion
    for (_i = 0; _i < text.length; _i++) {
      _target = text[_i];
      if (_i + 1 < text.length) _target_next = text[_i + 1];

      // Stores Tokenized character
      Symbol char;

      char = tokenizer();

      // if previously the sequence was a tag's name or property but the current character isn't
      // then add a [TagWord] with the [cachedString] to token list
      if (_tagWordSeq && char != Symbol.stringtext) {
        if (cacheString.isNotEmpty) {
          tokens.add(
            NamespaceWord(
              cacheString,
            ),
          );
        }
        _tagWordSeq = false;
        cacheString = '';
      }

      switch (char) {
        case Symbol.double_quots:
        case Symbol.single_quots:
          if (_normalTextSeq) {
            // probably out of tags so insert raw character to cache
            cacheString = '$cacheString$_target';
          } else if (_valueSeq) {
            // probably previous strings were value for a tag's property
            // so add it to tokens as NamespaceWords
            tokens.add(Text(cacheString));
            _valueSeq = false;
            cacheString = '';
          } else {
            // probably start of a value sequence for a tag's properties
            _valueSeq = true;
            cacheString = '';
          }
          break;
        case Symbol.assignment:
          if (!_normalTextSeq) {
            // The previous TagWord is probably not a tagname,
            // hence assign false to last TagWord
            var lastTagword =
                tokens.lastIndexWhere((token) => token is NamespaceWord);
            if (lastTagword >= 0) tokens[lastTagword].isTagname = false;
            tokens.add(char);
          } else if (_normalTextSeq) {
            // Out of tags so should use '=' in cacheString
            cacheString = '$cacheString$_target';
          }
          break;
        case Symbol.space:
          if (_normalTextSeq) {
            // probably out of tags so insert raw character to cache
            cacheString = '$cacheString$_target';
          } else {
            tokens.add(char);
            _tagWordSeq = true;
            cacheString = '';
          }
          break;
        // Out of tags so only normal texts exists
        case Symbol.instructionEnd:
        case Symbol.closeTag:
          _tagWordSeq = false;
          _valueSeq = false;
          _normalTextSeq = true;
          tokens.add(char);
          break;
        case Symbol.instruction:
        case Symbol.endTag:
        case Symbol.begTag:
          if (cacheString.isNotEmpty) {
            tokens.add(Text(cacheString));
            cacheString = '';
          }
          tokens.add(char);
          _tagWordSeq = true;
          _normalTextSeq = false;
          break;
        case Symbol.stringtext:
          cacheString = '$cacheString$_target';
          break;
        default:
          tokens.add(char);
      }
    }
  }

  /// [tokenizer] returns correct XML token identified from text
  Symbol tokenizer() {
    switch (_target) {
      case '<':
        if (_target_next == '/') {
          _i++;
          return Symbol.endTag;
        } else if (_target_next == '?') {
          _i++;
          return Symbol.instruction;
        }
        return Symbol.begTag;
      case '/':
        if (_target_next == '>') {
          _i++;
          return Symbol.selfCloseTag;
        }
        break;
      case '>':
        return Symbol.closeTag;
      case ' ':
        if (_valueSeq) {
          return Symbol.stringtext;
        }
        return Symbol.space;
      case '"':
        return Symbol.double_quots;
      case "'":
        return Symbol.single_quots;
      case '\n':
        return Symbol.lineBreak;
      case '\t':
        return Symbol.tabSpace;
      case '?':
        if (_target_next == '>') {
          _i++;
          return Symbol.instructionEnd;
        }
        return Symbol.stringtext;
      case '=':
        if (_valueSeq) {
          return Symbol.stringtext;
        }
        return Symbol.assignment;
    }
    return Symbol.stringtext;
  }
}

String toast(String text) {
  List<dynamic> tokenList;
  XmlParser parser = XmlParser(text);
  tokenList = parser.tokens;
  // print(tokenList);
  var doc_xml = parser.parse();
  print(doc_xml);
  // return tokenList.join();
}
