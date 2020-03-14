import 'dart:io';

import 'package:sample/verbose_print.dart';
import 'package:sample/xml_master/parser.dart';

import './get_content.dart';
import './globals.dart' as globals;
import 'handle_xml.dart';

/// Converts XML file's text to markdown and display it on console
void sample(File file) async {
  if (file == null) {
    print('[file] is null');
    exit(1);
  }
  // Raw content from file
  String content;
  // Parsed text from raw content
  String parsedText;

  // get raw file content
  content = await getContent(file);
  vPrint(content);
  // Parse & Make a DOM tree
  // [UNDO] parsedText = XMLHandler(content).toString();
  parsedText = toast(content);
  // Convert to Markdown
  // Print to console
  print('Parsed:\n$parsedText');

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
