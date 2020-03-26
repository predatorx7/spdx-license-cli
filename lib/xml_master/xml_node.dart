import 'package:meta/meta.dart' show required;
import 'package:sample/matcher.dart' as mat;
import 'package:sample/xml_master/format.dart';
import 'package:validators/validators.dart';
import 'parser.dart' show Text;

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
  String text = '';

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

  bool setText(Text text) {
    bool hasOther;
    for (var i = 0; i < text.text.length; i++) {
      var tx = text.text[i];
      if (tx != ' ' || tx != '\t') {
        hasOther = true;
      }
    }
    if (!hasOther) {
      return false;
    }
    this.text += text.toText();
    return this.text.isNotEmpty;
  }

  /// Returns true if children exists
  bool hasChildren() {
    if (children?.isEmpty ?? true) return false;
    return true;
  }

  bool hasText() {
    if (text != null ?? text != '') return true;
    return false;
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

  String toMarkdown({List unsolvedStyles}) {
    String message;
    message = '';
    unsolvedStyles ??= [];
    // pre-Styling
    if (tagName == 'br') {
      message += '\n';
      return message;
    }
    if (tagName == 'titleText') {
      unsolvedStyles.add(tagName);
    }
    if (tagName == 'p') {
      if (unsolvedStyles.contains('titleText')) {
        message += '# ';
        unsolvedStyles.remove('titleText');
      } else {
        message += '\n';
      }
    }

    if (tagName == 'bullet') {
      var bulletType;
      if (isNumeric(text[0])) {
        bulletType = '1. ';
      } else {
        bulletType = '- ';
      }
      text = bulletType + text.substring(3, text.length);
      // return message;
      return '$message${XmlFormatString(text).format()}\n\n';
    }

    // Content ====
    if (hasChildren()) {
      for (var node in children) {
        message += node.toMarkdown(unsolvedStyles: unsolvedStyles);
      }
    }
    if (hasText()) {
      if (mat.isURL(text.trim())) {
        message += '[$tagName](${text.trim()})\n';
      } else {
        message = '$message${XmlFormatString(text).format()}';
      }
    }

    // ====
    // post Styling
    if (tagName == 'p') {
      message += '\n\n';
    }
    return message;
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

    if (isSelfClosing()) {
      message = '$message />\n';
      return message;
    }

    message = '$message>';

    if (hasChildren()) {
      for (var node in children) {
        message += '\n$node';
      }
      message += '\n</$tagName>\n';
    }

    if (hasText()) {
      message += '$text</$tagName>\n';
      return message;
    }

    return message;
  }
}
