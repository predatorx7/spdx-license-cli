import './xml_document.dart';

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