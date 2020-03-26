import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:validators/validators.dart' as vald;

bool isURL(String str) {
  return vald.isURL(str);
}

Future<bool> isLocalFile(String str) async {
  return await io.File(str).exists();
}

Future<bool> urlExists(String url) async {
  final response = await http.head(url);
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}
