import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart';

abstract class WebDownloadHelper {
  static void downloadFile(List<int> bytes, String fileName) {
    saveFileWeb(bytes, fileName);
  }
}
