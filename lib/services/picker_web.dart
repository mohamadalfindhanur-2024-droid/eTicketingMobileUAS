import 'dart:async';
import 'dart:html' as html;

Future<String?> pickAttachmentFile(String source) async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();
  
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      completer.complete(files[0].name);
    } else {
      completer.complete(null);
    }
  });
  
  return completer.future;
}
