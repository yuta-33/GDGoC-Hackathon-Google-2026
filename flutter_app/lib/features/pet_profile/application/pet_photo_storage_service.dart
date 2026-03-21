import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final petPhotoStorageServiceProvider = Provider<PetPhotoStorageService>((_) {
  return PetPhotoStorageService();
});

class PetPhotoStorageService {
  Future<Directory> ensurePhotoDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${baseDir.path}/pet_photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  Future<String> savePhoto({
    required File sourceFile,
    String? previousPhotoPath,
  }) async {
    final photoDir = await ensurePhotoDirectory();
    final extension = _fileExtension(sourceFile.path);
    final targetPath =
        '${photoDir.path}/pet_${DateTime.now().millisecondsSinceEpoch}$extension';
    final copiedFile = await sourceFile.copy(targetPath);

    if (previousPhotoPath != null && previousPhotoPath != copiedFile.path) {
      final previousFile = File(previousPhotoPath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    return copiedFile.path;
  }

  Future<String> saveBundledPhoto({
    required String assetPath,
    String? previousPhotoPath,
  }) async {
    final photoDir = await ensurePhotoDirectory();
    final extension = _fileExtension(assetPath);
    final targetPath =
        '${photoDir.path}/pet_${DateTime.now().millisecondsSinceEpoch}$extension';
    final byteData = await rootBundle.load(assetPath);
    final file = File(targetPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (previousPhotoPath != null && previousPhotoPath != file.path) {
      final previousFile = File(previousPhotoPath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    return file.path;
  }

  String _fileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0) {
      return '.jpg';
    }
    return path.substring(lastDot);
  }
}
