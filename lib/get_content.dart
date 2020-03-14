import 'dart:io';

Future<String> getContent(File file) async {
  String contents;
  if (await file.exists()) {
    // Read file
    contents = await file.readAsString();
    return contents;
  } else {
    print('[getContent] Provided file is null or doesn\'t exists');
  }
  return null;
}
