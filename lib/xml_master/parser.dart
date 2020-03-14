class IllegalTagwordException implements Exception {
  String message;
  final word;
  IllegalTagwordException([this.word]) {
    if (message == null) {
      message = 'Tagword has illegal character';
    } else {
      message = '"$word" has illegal character';
    }
    message = 'IllegalTagword: $message';
  }

  @override
  String toString() {
    if (message == null) {
      return 'Tagname has illegal character';
    } else {
      message = '"$word" has illegal character';
    }
    return 'IllegalTagname: $message';
  }
}

class IllegalTokenException implements Exception {
  String token;
  int index;
  IllegalTokenException(token, index);

  @override
  String toString() {
    return 'IllegalTokenException: Illegal token "$token" at $index';
  }
}

enum Symbol {
  tagBeg,
  tagEnd,
  close,
  double_quots,
  single_quots,
  lineBreak,
  space,
  question,
  stringtext,
  instruction,
  instructionEnd,
  assignment,
  tabSpace,
  ignore,
}

class Text {
  final String text;
  // normal text
  Text(this.text);

  /// [Text] to String
  String toText() => text;
  @override

  /// [Text] to String with double quotes
  String toString() => '"$text"';
}

class TagWord {
  final String tagWord;

  /// [TagWord] of a tag which is a property name or tagname
  TagWord(this.tagWord) {
    if (!_isValidTagword(tagWord)) {
      throw IllegalTagwordException(tagWord);
    }
  }

  /// [TagWord] to String without quotes
  String toText() => tagWord;
  @override

  /// [TagWord] to String with single quotes
  String toString() => "'$tagWord'";
  static bool _isValidTagword(String text) {
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
    if ((text[0] ?? '') == '-' || (text[0] ?? '') == '.') {
      return false;
    }
    try {
      var number = double.parse(text[0]);
      return false;
    } on FormatException {
      // ignore
    }

    for (var syms in notAllowed) {
      if (text.contains(syms)) {
        return false;
      }
    }
    return true;
  }
}

class XmlParser {
  final String text;
  int i = 0;
  String _target, _target_next;
  bool valueSeq;
  bool tagWordSeq;
  bool normalTextSeq;
  XmlParser(this.text);
  List<dynamic> lexer() {
    List<dynamic> tokens;
    tokens = [];
    valueSeq = false;
    tagWordSeq = false;
    normalTextSeq = false;
    String cacheTagword;
    String cacheText;

    for (i = 0; i < text.length; i++) {
      _target = text[i];
      if (i + 1 < text.length) _target_next = text[i + 1];
      Symbol char;
      char = tokenizer();
      if (tagWordSeq && char != Symbol.stringtext) {
        try {
          tokens.add(
            TagWord(
              cacheTagword,
            ),
          );
        } catch (e) {
          print(
              "at index $i\n$char\n$tokens\n$valueSeq\n$tagWordSeq\n$normalTextSeq\n$cacheTagword\n$cacheText");
          rethrow;
        }
        tagWordSeq = false;
        cacheTagword = '';
      }
      switch (char) {
        case Symbol.double_quots:
        case Symbol.single_quots:
          if (normalTextSeq) {
            cacheText = '$cacheText$_target';
            break;
          }
          if (valueSeq) {
            tokens.add(Text(cacheText));
          }
          valueSeq = !valueSeq;
          cacheText = '';
          break;
        case Symbol.assignment:
          // TODO: To fix
          // if (tagWordSeq) {
          //   tagWordSeq = false;
          // } else {
          //   throw IllegalTokenException(_target, i);
          // }
          tokens.add(char);
          break;
        case Symbol.instructionEnd:
        case Symbol.close:
          if (tagWordSeq) {
            tokens.add(
              TagWord(
                cacheTagword,
              ),
            );
          }
          tagWordSeq = false;
          valueSeq = false;
          normalTextSeq = true;
          cacheText = '';
          tokens.add(char);
          break;
        case Symbol.tagEnd:
        case Symbol.tagBeg:
          if (cacheText.isNotEmpty) {
            tokens.add(Text(cacheText));
          }
          tokens.add(char);
          tagWordSeq = true;
          normalTextSeq = false;
          break;
        case Symbol.space:
          tokens.add(char);
          break;
        case Symbol.stringtext:
          if (valueSeq) {
            cacheText = '$cacheText$_target';
            break;
          }
          if (!tagWordSeq && !normalTextSeq) {
            tagWordSeq = true;
            cacheTagword = '';
          }
          if (tagWordSeq) {
            cacheTagword = '$cacheTagword$_target';
          }
          break;
        case Symbol.ignore:
          break;
        default:
          tokens.add(char);
      }
    }
    return tokens;
  }

  Symbol tokenizer() {
    switch (_target) {
      case '<':
        if (_target_next == '/') {
          i++;
          return Symbol.tagEnd;
        } else if (_target_next == '?') {
          i++;
          return Symbol.instruction;
        }
        return Symbol.tagBeg;
      case '/':
        if (_target_next == '>') {
          i++;
          return Symbol.close;
        }
        break;
      case '>':
        return Symbol.close;
      case ' ':
        if (valueSeq) {
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
          i++;
          return Symbol.instructionEnd;
        }
        return Symbol.stringtext;
      case '=':
        if (valueSeq) {
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
