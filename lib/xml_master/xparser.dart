import 'dart:collection';

class IllegalTagnameException implements Exception {
  final message;

  IllegalTagnameException([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'Tagname has illegal character';
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
  tabSpace
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

class Character {
  final String character;
  Character(this.character);
  String toText() => character;
  @override
  String toString() => "'$character'";
}

class TagWord {
  final String tagWord;
  final bool isTagname;

  /// [TagWord] of a tag which is a property name or tagname
  TagWord(this.tagWord, {this.isTagname = true}) {
    if (!_isValidTagword(tagWord)) {
      throw IllegalTagnameException();
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
    if (text[0] == '-' || text[0] == '.') {
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
  bool normText;
  bool tagWord;
  XmlParser(this.text);
  List<dynamic> lexer() {
    List<dynamic> tokens;

    // List<Character> characters;
    // characters = [];
    tokens = [];
    normText = false;
    tagWord = false;
    String cacheTagword;
    String cacheText;
    for (i = 0; i < text.length; i++) {
      _target = text[i];
      if (i + 1 < text.length) _target_next = text[i + 1];
      Symbol char;
      char = tokenizer();
      switch (char) {
        case Symbol.double_quots:
        case Symbol.single_quots:
          if (normText) {
            tokens.add(Text(cacheText));
          }
          normText = !normText;
          cacheText = '';
          break;
        case Symbol.assignment:
          if (tagWord) {
            tagWord = false;
            tokens.add(
              TagWord(
                cacheTagword,
                isTagname: false,
              ),
            );
            cacheTagword = '';
          } else {
            throw IllegalTokenException(_target, i);
          }
          tokens.add(char);
          break;
        case Symbol.close:
          if (tagWord) {
            tagWord = false;
            tokens.add(
              TagWord(
                cacheTagword,
                isTagname: false,
              ),
            );
          }
          normText = true;
          cacheText = '';
          tokens.add(char);
          break;
        case Symbol.tagBeg:
          normText = false;
          tokens.add(Text(cacheText));
          tokens.add(char);
          break;
        case Symbol.stringtext:
          if (normText) {
            cacheText = '$cacheText$_target';
            break;
          }
          if (tokens.isNotEmpty) {
            if (tagWord && tokens.last == Symbol.space) {
              tokens.add(
                TagWord(
                  cacheTagword,
                  isTagname: false,
                ),
              );
              cacheTagword = '';
            }
          }
          if (!tagWord) {
            tagWord = true;
            cacheTagword = '';
          }
          cacheTagword = '$cacheTagword$_target';
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

      case '>':
        return Symbol.close;

      case ' ':
        if (normText) {
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
        if (normText) {
          return Symbol.stringtext;
        }
        return Symbol.assignment;
      default:
        return Symbol.stringtext;
    }
  }
}

String toast(String text) {
  print('[toast] using tokenizer');
  List tokenList;
  tokenList = XmlParser(text).lexer();
  print(tokenList);
  print('[toast] joining');
  return tokenList.join();
}
