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

enum XmlNodeType {
  root,
  element,
  text,
  comment,
  noTextElement,
}

/// This as An XML node
class XmlNode {
  /// Tag-name for this [XmlNode]
  String tagName;

  String namespace;

  /// [XmlNode] type
  XmlNodeType type;

  /// Attributes as key-value pairs
  Map<String, dynamic> attributes = {};

  /// Parent [XmlNode]
  XmlNode parent;

  /// Text stored by this [XmlNode]
  String text;

  /// Children under this [XmlNode]
  List<XmlNode> children = [];

  /// A XmlNode
  XmlNode();

  factory XmlNode.create(XmlNode parentNode) {
    var x = XmlNode();
    x.parent = parentNode;
    return x;
  }

  bool isSelfClosing() {
    return (text?.isEmpty ?? true) && (childCount == 0);
  }

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

  /// Returns true if children exists
  bool hasChildren() {
    if (children?.isEmpty ?? true) return false;
    return true;
  }

  bool hasText() {
    if (text != null ?? text != '') return false;
    return true;
  }

  /// Number of child nodes in [children] of this [XmlNode]
  int get childCount => children.length;

  /// This node's position from root
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

  @override
  String toString() {
    String message;
    message = '<${tagName}';
    if (attributes?.isNotEmpty ?? false) {
      for (var attribute in attributes.keys) {
        message = '$message $attribute = "${attributes[attribute]}"';
      }
    }
    if (this.isSelfClosing()) {
      message = '$message />\n';
      return message;
    }
    message = '$message >';
    if (this.hasChildren()) {
      for (var node in children) {
        message += '\n$node';
      }
    }

    if (this.hasText()) {
      message += '$text</$tagName>\n';
      return message;
    }

    message += '\n</$tagName>\n';
    return message;
  }
}
