import 'package:xml/xml.dart' as xml;
import 'verbose_print.dart';

class XMLHandler {
  final xml.XmlDocument _document;

  xml.XmlDocument get document => _document;

  XMLHandler(String xmlText) : _document = xml.parse(xmlText) {
    vPrint('XML:\n$xmlText');
  }

  @override
  String toString() {
    String textual;
    textual = document.descendants
        .where((node) => node is xml.XmlText && node.text.trim().isNotEmpty)
        .join('\n');
    textual = xml.XmlDefaultEntityMapping.xml().decode(textual);
    return textual;
  }
}
