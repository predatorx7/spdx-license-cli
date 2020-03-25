import './xml_node.dart';

/// [XmlDocument] is an XML document tree.
class XmlDocument {
  /// root [XmlNode] of this document (descendant)
  XmlNode root;

  String version;

  String encoding;

  /// [tabSize] will be the number of spaces to represent a single tab
  int tabSize;

  XmlDocument(
    this.version,
    this.encoding,
  );

  String toXmlString() => toString();

  @override
  String toString() {
    String message;
    message = '<?xml version="$version" encoding="$encoding"?>\n';
    message = '$message$root';
    return message;
  }
}
