import 'package:sample/xml_master/stack.dart';
import 'package:sample/xml_master/xml_document.dart';
import 'package:sample/xml_master/xml_node.dart';

import './exception.dart';

/// [Symbol] represents symbols used in sample XML
enum Symbol {
  /// A '<' smaller than symbol representing opening tag's beginning
  tagBeg,

  /// A '</' symbol representing closing tag's beginning
  tagEnd,

  /// '>' symbol
  close,

  /// '/>' symbol
  selfClose,

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
class TagWord {
  /// The [String] this holds
  final String tagWord;
  bool _isTagname = true;

  bool get isTagname => _isTagname;

  set isTagname(bool isTagname) {
    _isTagname = isTagname;
  }

  /// [TagWord] of a tag which is a property name or tagname
  TagWord(this.tagWord) {
    // check if tagword uses legal characters
    if (!_isValidTagword(tagWord)) {
      throw IllegalTagwordException(tagWord);
    }
  }

  /// [TagWord] to String without quotes
  String toText() => tagWord;
  @override

  /// [TagWord] to String with single quotes
  String toString() => "'$tagWord'";

  /// Check if [String] is a valid [TagWord]
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
  XmlParser(this.text) {
    // Creating tokens
    lexer();
    // Parsing to XML tree
    parser();
  }

  /// [parser] parses and converts to [XmlDocument] based on token context
  void parser() {
    var target, target_next;
    List<String> tagStack;
    tagStack = [];
    var docVersion = '1.0';
    var docEncoding = 'UTF-8';
    var docSize = 1;
    String instTag;
    String instProp;
    String instPropVal;
    XmlDocument document;
    XmlNode prevNode;
    XmlNode currentNode;
    XmlNode node1;
    XmlNode node2;
    XmlNode node3;
    bool tabSpacesFixed = false;
    bool awaitValue = false;
    bool awaitInstructions = false;
    bool awaitTagname = false;
    bool inEndTag = false;
    bool documentDeclarationCompleted = false;
    String awaitValueOfProp;
    for (var j = 0; j < tokens.length; j++) {
      target = tokens[j];
      print(tagStack);
      print(target);
      if (j + 1 < tokens.length) target_next = tokens[j + 1];
      if (target is Symbol) {
        switch (target) {
          case Symbol.tagBeg:
            if (document == null) {
              currentNode = XmlNode();
              document =
                  XmlDocument(currentNode, docVersion, docEncoding, docSize);
              currentNode.type = XmlNodeType.root;
            } else if (currentNode == null) {
              currentNode = XmlNode();
              document.root = currentNode;
              currentNode.type = XmlNodeType.root;
              document.size++;
              currentNode.type = XmlNodeType.element;
            } else if (prevNode != null) {
              if (prevNode.tagName == currentNode.parent.tagName) {
                currentNode = prevNode;
                prevNode = prevNode.parent;
              } else {
                throw UnexpectedTokenException('Parsing error.');
              }
            } else {
              prevNode = currentNode;
              currentNode = XmlNode();
              currentNode.parent = prevNode;
              document.size++;
              prevNode.addChild(currentNode);
              currentNode.type = XmlNodeType.element;
            }
            awaitTagname = true;
            break;
          case Symbol.tagEnd:
            inEndTag = true;
            currentNode = prevNode;
            prevNode = null;
            break;
          case Symbol.double_quots:
            // ignore, lexer handled
            break;
          case Symbol.single_quots:
            // ignore, lexer handled
            break;
          case Symbol.lineBreak:
            continue;
            break;
          case Symbol.space:
            continue;
            break;
          case Symbol.stringtext:
            // ignore, lexer handled
            break;
          case Symbol.instruction:
            // To get document description
            awaitInstructions = true;

            break;
          case Symbol.instructionEnd:
            // To complete document description
            if (awaitInstructions && !documentDeclarationCompleted) {
              if (instTag == 'xml') {
                if (document == null) {
                  document =
                      XmlDocument(null, docVersion, docEncoding, docSize);
                } else {
                  document.version = docVersion;
                  document.encoding = docEncoding;
                  documentDeclarationCompleted = true;
                }
              }
              awaitInstructions = false;
              continue;
            }
            break;
          case Symbol.assignment:
            try {
              if (!awaitValue) {
                throw UnexpectedTokenException(
                    'Unexpected assignment operator');
              }
            } catch (e) {
              print('index: $j\n$tokens');
            }
            break;
          case Symbol.tabSpace:
            // ignore
            break;
          case Symbol.close:
            if (inEndTag) {
              if (tagStack.removeLast() == currentNode.tagName) {
                prevNode = currentNode;
                currentNode = null;
                inEndTag = false;
              } else {
                print(currentNode);
                print(prevNode);
                throw UnexpectedTokenException(
                    'start & end tagnames don\'t match.');
              }
            }
            awaitValue = false;
            break;
          case Symbol.selfClose:
            tagStack.removeLast();
            prevNode = currentNode;
            currentNode = null;
            break;
        }
      }
      if (target is TagWord) {
        if (inEndTag && tagStack.last != target.tagWord) {
          throw UnexpectedTokenException('start & end tagnames don\'t match.');
        }

        if (awaitInstructions && !documentDeclarationCompleted) {
          // For complete document declaration
          if (instTag == null) {
            instTag = target.tagWord;
          }
          if (instTag == 'xml') {
            instProp = target.tagWord;
            awaitValue = true;
          }
          continue;
        }
        if (awaitTagname) {
          currentNode.tagName = target.tagWord;
          tagStack.add(currentNode.tagName);
          awaitTagname = false;
          continue;
        }
        if (!inEndTag) {
          /// End tag don't have attributes
          currentNode.attributes[target.tagWord] = '';
          awaitValue = true;
          awaitValueOfProp = target.tagWord;
        }
      }
      if (target is Text) {
        if (awaitInstructions && !documentDeclarationCompleted && awaitValue) {
          // For complete document declaration
          if (instTag == 'xml') {
            if (instProp == 'version') {
              docVersion = target.text;
            }
            if (instProp == 'encoding') {
              docEncoding = target.text;
            }
            awaitValue = false;
          }
          continue;
        }
        if (awaitValue) {
          try {
            currentNode.attributes[awaitValueOfProp] = target.text;
          } catch (e) {
            print('index: $j');
            print('$tokens');
            rethrow;
          }
          awaitValue = false;
          awaitValueOfProp = null;
          continue;
        }

        /// Check and adjust if tabspaces out of tag else throw
        if (currentNode == null) {
          bool isFullSpace;
          for (var char in target.text.split('')) {
            isFullSpace = (char == ' ');
            if (!isFullSpace) {
              break;
            }
          }
          if (!tabSpacesFixed && isFullSpace) {
            tabSpacesFixed = true;
            document.tabSize = target.text.length;
            continue;
          } else if (tabSpacesFixed && isFullSpace) {
            var tabs = (target.text.length / document.tabSize).round();
            if (tabs == 1) {
              // a single tab
            } else {
              // multiple tabs
            }
            continue;
          }
          // Not spaces
        }

        /// handle tab spaces
        if (currentNode == null) {
          currentNode.type = XmlNodeType.text;
        } else {
          currentNode.type = XmlNodeType.element;
        }
      }
    }
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
            TagWord(
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
            // so add it to tokens as Text
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
                tokens.lastIndexWhere((token) => token is TagWord);
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
        case Symbol.close:
          _tagWordSeq = false;
          _valueSeq = false;
          _normalTextSeq = true;
          tokens.add(char);
          break;
        case Symbol.instruction:
        case Symbol.tagEnd:
        case Symbol.tagBeg:
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
          return Symbol.tagEnd;
        } else if (_target_next == '?') {
          _i++;
          return Symbol.instruction;
        }
        return Symbol.tagBeg;
      case '/':
        if (_target_next == '>') {
          _i++;
          return Symbol.selfClose;
        }
        break;
      case '>':
        return Symbol.close;
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
  print('[toast] using tokenizer');
  List<dynamic> tokenList;
  tokenList = XmlParser(text).tokens;
  print(tokenList);
  print('[toast] joining');
  return tokenList.join();
}
