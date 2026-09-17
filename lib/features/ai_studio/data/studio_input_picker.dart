import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itun/features/ai_studio/data/ai_studio_service.dart';

class StudioInputPicker {
  const StudioInputPicker();

  Future<StudioInput?> pickAudio() =>
      _pick(type: FileType.custom, allowedExtensions: const ['wav']);

  Future<StudioInput?> pickDocument() => _pick(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
  );

  Future<StudioInput?> capturePage() => _camera();

  Future<StudioInput?> _camera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2480,
      imageQuality: 92,
    );
    if (picked == null) return null;
    return StudioInput(bytes: await picked.readAsBytes(), name: picked.name);
  }

  Future<StudioInput?> _pick({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return StudioInput(bytes: bytes, name: file.name);
  }
}

final studioInputPickerProvider = Provider<StudioInputPicker>(
  (ref) => const StudioInputPicker(),
);
