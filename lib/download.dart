import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sample/globals.dart' as globals;
import 'package:sample/verbose_print.dart';

Future<File> download(String fileAddress) async {
  var filename = path.basename(Uri.parse(fileAddress).path);
  vPrint('[download] Downloading $filename from $fileAddress');
  try {
    Directory tempDir;
    String downloadedFilePath;
    File downloadedFile;
    tempDir = await Directory(globals.tempPath).create(recursive: true);
    await HttpClient()
        .getUrl(
          Uri.parse(fileAddress),
        )
        .then(
          (HttpClientRequest request) => request.close(),
        )
        .then(
      (HttpClientResponse response) {
        downloadedFilePath = path.join(tempDir.path, filename);
        downloadedFile = File(downloadedFilePath);
        return response.pipe(
          downloadedFile.openWrite(),
        );
      },
    );
    String message;
    var error404msg = '404: Not Found\n';
    message = await downloadedFile.readAsString();
    if (message == error404msg) {
      // probably a "404: Not Found" error
      await downloadedFile.delete();
      throw HttpException(
          'Download failed. (Status code 404) File not found at the provided URL.');
    }
    vPrint('[download] Downloaded ${path.basename(downloadedFilePath)}');
    return downloadedFile;
  } on SocketException {
    vPrint('[download] Download failed. Internet might not be available.');
    rethrow;
  }
}
