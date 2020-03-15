import './xml_node.dart';

class XmlDocument {
  XmlNode _root;

  XmlNode get root => _root;

  set root(XmlNode root) {
    _root = root;
  }

  String _version;

  String get version => _version;

  set version(String version) {
    _version = version;
  }

  String _encoding;

  String get encoding => _encoding;

  set encoding(String encoding) {
    _encoding = encoding;
  }

  int _size;

  int get size => _size;

  set size(int size) {
    _size = size;
  }

  XmlDocument(this._root, this._version, this._encoding, this._size);
}
