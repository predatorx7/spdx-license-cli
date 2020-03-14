import './exception.dart';

/// [Symbol] represents symbols used in sample XML
enum Symbol {
  /// A '<' smaller than symbol representing opening tag's beginning
  tagBeg,

  /// A '</' symbol representing closing tag's beginning
  tagEnd,

  /// '>' symbol
  close,

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

  XmlParser(this.text);

  /// [parser] parses and converts to [XmlDocument] based on token context
  void parser() {}

  /// [lexer] adds more meaning to tokens
  List<dynamic> lexer() {
    List<dynamic> tokens;
    tokens = [];
    _valueSeq = false;
    _tagWordSeq = false;
    _normalTextSeq = false;

    // Stores String temporarily
    String cacheString;

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
        tokens.add(
          TagWord(
            cacheString,
          ),
        );
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
    return tokens;
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
          return Symbol.close;
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
  tokenList = XmlParser(text).lexer();
  print(tokenList);
  print('[toast] joining');
  return tokenList.join();
}
