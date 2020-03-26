import 'dart:io';

import 'package:sample/verbose_print.dart';
import 'package:sample/xml_master/parser.dart';

import './get_content.dart';
import './globals.dart' as globals;

/// Converts XML file's text to markdown and display it on console
void sample(File file) async {
  if (file == null) {
    print('[file] is null');
    exit(1);
  }
  // Raw content from file
  String content;
  // Parsed text from raw content
  String markdownText;

  // get raw file content
  content = await getContent(file);
  vPrint(content);
  // Parse & Make a DOM tree
  // [UNDO] parsedText = XMLHandler(content).toString();
  var parser = XmlParser(content);
  var xmlDocument = parser.parse();
  markdownText = xmlDocument.toMarkdown();
  // Convert to Markdown
  // Print to console
  print('$markdownText');

  // cleaning up temp files and downloads if specified
  if (globals.deleteDownloads) {
    // Deleting file as it has no further use.
    await file.delete(recursive: true);
  }
  if (globals.deleteTemp) {
    await Directory.fromUri(Uri.parse(globals.tempPath))
        .delete(recursive: true);
  }
}
