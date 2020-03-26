class XmlFormatString {
  final String text;
  const XmlFormatString(this.text);

  static String decode(String input) {
    final output = StringBuffer();
    final length = input.length;
    var position = 0;
    var start = position;
    while (position < length) {
      final value = input.codeUnitAt(position);
      if (value == 38) {
        final index = input.indexOf(';', position + 1);
        if (position + 1 < index) {
          final entity = input.substring(position + 1, index);
          final value = _decodeEntity(entity);
          if (value != null) {
            output.write(input.substring(start, position));
            output.write(value);
            position = index + 1;
            start = position;
          } else {
            position++;
          }
        } else {
          position++;
        }
      } else {
        position++;
      }
    }
    output.write(input.substring(start, position));
    return output.toString();
  }

  static String _decodeEntity(String input) {
    /// XML named character references.
    final entities = {
      'amp': '&', // ampersand
      'apos': "'", // apostrophe
      'gt': '>', // greater-than sign
      'lt': '<', // less-than sign
      'quot': '"', // quotation mark
    };
    if (input.length > 1 && input[0] == '#') {
      if (input.length > 2 && (input[1] == 'x' || input[1] == 'X')) {
        // Hexadecimal character reference.
        return String.fromCharCode(int.parse(input.substring(2), radix: 16));
      } else {
        // Decimal character reference.
        return String.fromCharCode(int.parse(input.substring(1)));
      }
    } else {
      // Named character reference.
      return entities[input];
    }
  }

  String format() {
    var str = text.trim();
    var newStr = '';
    var prevChar = '';
    var spaceCount = 0;
    for (var i = 0; i < str.length; i++) {
      var cur = str[i];
      if (cur == ' ') {
        spaceCount++;
      } else if (spaceCount > 1) {
        if (cur == '\t') {
          cur == '';
        }
        newStr += ' $cur';
        spaceCount = 0;
      } else {
        if (prevChar == ' ') {
          newStr += ' ';
        }
        newStr += cur;
      }
      prevChar = cur;
    }
    return decode(newStr);
  }
}
