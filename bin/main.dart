import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:sample/globals.dart' as globals;
import 'package:sample/download.dart' as download;
import 'package:sample/matcher.dart' as match;
import 'package:sample/sample.dart' as sample;
import 'package:sample/verbose_print.dart';

// [target]'s type ie URL or local file address
enum _TargetType { url, filePath, spdxURL, none }

void main(List<String> arguments) async {
  // The [target] file path or URL
  String target;

  // The [target] relative path to hardcoded address
  String htarget;

  // Hardcoded address of spdx license list in xml
  final spdxLicensePath =
      'https://raw.githubusercontent.com/spdx/license-list-XML/master/src';

  // The file which will held string from [target]
  File file;

  // [target]'s type ie URL or local file address
  _TargetType useAs;

  // To handle command-line arguments
  ArgParser parser;
  ArgResults parsedArgs;

  parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Show more verbose output',
        callback: (bool verbose) {
      globals.beVerbose = verbose;
    })
    ..addFlag('help', abbr: 'h', help: 'Show this help',
        callback: (bool showHelp) {
      if (showHelp) {
        print(parser.usage);
        exit(1);
      }
    })
    ..addFlag('del-temp',
        abbr: 'd', help: 'Delete downloads & temporary folder after completion',
        callback: (bool answer) {
      globals.deleteTemp = answer;
      globals.deleteDownloads = answer;
    })
    ..addOption('path',
        abbr: 'p',
        help:
            'Either a web address or path (or relative path) of file\'s local location',
        defaultsTo: '')
    ..addOption('hardcoded-path',
        abbr: 'x',
        help: 'File\'s location relative to the spdx license list',
        defaultsTo: '');

  parsedArgs = parser.parse(arguments);

  // Obtaining [target]'s path and validating it
  target = parsedArgs['path'];
  htarget = parsedArgs['hardcoded-path'];
  if (target.isEmpty && htarget.isEmpty) {
    print('File path not provided');
    print(parser.usage);
    exit(1);
  } else if (htarget.isNotEmpty && match.isURL('$spdxLicensePath/$htarget')) {
    useAs = _TargetType.spdxURL;
  } else if (await match.isLocalFile(target)) {
    useAs = _TargetType.filePath;
  } else if (await match.urlExists(target)) {
    useAs = _TargetType.url;
  } else {
    useAs = _TargetType.none;
  }

  // Fetching [target] file
  switch (useAs) {
    case _TargetType.filePath:
      // Copies SPDX XML License file to temp folder
      file = await File(target)
          .copy(path.join(globals.tempPath, path.basename(target)));
      break;
    case _TargetType.url:
      // Downloads SPDX XML License file
      // & Copies SPDX XML License file to temp folder
      file = await download.download('$target');
      break;
    case _TargetType.spdxURL:
      // Downloads SPDX XML License file
      // & Copies SPDX XML License file to temp folder
      file = await download.download('$spdxLicensePath/$htarget');
      break;
    case _TargetType.none:
      print('File not found');
      exit(1);
      break;
    default:
      vPrint('File: $target, Used as: $useAs');
      print(parser.usage);
      exit(1);
  }

  sample.sample(file);
}
