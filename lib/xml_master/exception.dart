class UnexpectedTokenException implements Exception {
  final message;

  UnexpectedTokenException([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'Recieved an unexpected token in the XML document';
    }
    return 'UnexpectedToken: $message';
  }
}

class XmlParsingException implements Exception {
  final message;

  XmlParsingException([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'Parsing failed';
    }
    return 'XmlParsing: $message';
  }
}

class IllegalTagwordException implements Exception {
  String message;
  final word;
  IllegalTagwordException([this.word]) {
    if (word == null) {
      message = 'Tagword has illegal character';
    } else {
      message = '"$word" has illegal character';
    }
    message = 'IllegalTagword: $message';
  }

  @override
  String toString() {
    return message;
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
