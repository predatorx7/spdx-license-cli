import './xml_node.dart';

class XmlDocument {
  final XmlNode root;
  final int version;
  final String encoding;
  final int size;
  XmlDocument(this.root, this.version, this.encoding, this.size);
}
