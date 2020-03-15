import './xml_node.dart';

/// [XmlDocument] is an XML document tree.
class XmlDocument {
  /// root [XmlNode] of this document (descendant)
  XmlNode root;

  String version;

  String encoding;

  int size;

  /// [tabSize] will be the number of spaces to represent a single tab
  int tabSize;

  XmlDocument(this.root, this.version, this.encoding, this.size);

  String toXmlString() => toString();

  @override
  String toString() {
    String message;
    message = '<?xml version="$version" encoding="$encoding"?>\n';
    XmlNode current;
    message = '$message$current';
    return message;
  }
}
