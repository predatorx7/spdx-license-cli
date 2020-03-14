import 'package:meta/meta.dart' show required;

class RootNodeDeleteException implements Exception {
  final message =
      'Dart is garbage collected, so if this is a root node then it can be deleted if reference to this [Node] is removed.';

  RootNodeDeleteException();

  @override
  String toString() {
    return 'RootNodeDeleteException: Root node not deleted';
  }
}

class XmlNode {
  /// Tag-name for this [XmlNode]
  String tagName;

  /// Attributes as key-value pairs
  Map<String, int> attributes;

  /// Parent [XmlNode]
  XmlNode parent;

  /// Text stored by this [XmlNode]
  String text;

  /// Children under this [XmlNode]
  List<XmlNode> children;

  /// Constructs a Root Node
  XmlNode.root({
    @required this.tagName,
    this.children,
  });

  /// Constructs an Element Node
  XmlNode.element({
    @required this.tagName,
    @required this.parent,
    this.text,
    this.children,
  });

  /// Constructs a Text Node
  XmlNode.text({
    @required this.tagName,
    @required this.parent,
    @required this.text,
  });

  XmlNode.comment({
    this.text,
  });

  /// Delete this Node & it's children
  static void delete(XmlNode node) {
    // [delete] dart is garbage collected
    // for (var childNode in node.children) {
    //   delete(childNode);
    // }
    if (node.parent != null) {
      node.parent.removeChild(node);
    } else {
      // dart is garbage collected, so if this is a root node then
      // it can be deleted if reference to this [Node] is removed.
      throw RootNodeDeleteException();
    }
  }

  /// Appends child in the childrens of this [XmlNode]
  void addChild(XmlNode node) {
    children.add(node);
  }

  /// Remove a child
  void removeChild(XmlNode node) {
    children.removeWhere((XmlNode i) => i.tagName == node.tagName);
  }

  // Returns true if children exists
  bool hasChildren() {
    if (children?.isEmpty ?? true) return false;
    return true;
  }

  int positionFromRoot() {
    if (parent == null) return 0;
    return parent.positionFromRoot() + 1;
  }

  /// Returns list of elements/node matching with element name
  List<XmlNode> getElementsByName(String name) {
    List<XmlNode> matchedElements;
    matchedElements = [];
    children.forEach((XmlNode element) {
      if (element.tagName == name) {
        matchedElements.add(element);
      }
    });
    return matchedElements;
  }
}