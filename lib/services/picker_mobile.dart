import 'package:image_picker/image_picker.dart';

Future<String?> pickAttachmentFile(String source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
  );
  return image?.name;
}
