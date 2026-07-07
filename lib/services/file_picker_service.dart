import 'picker_stub.dart'
  if (dart.library.html) 'picker_web.dart'
  if (dart.library.io) 'picker_mobile.dart';

class FilePickerService {
  static Future<String?> pickFile(String source) {
    return pickAttachmentFile(source);
  }
}
