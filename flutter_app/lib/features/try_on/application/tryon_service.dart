import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/pet_profile.dart';
import '../../../core/models/tryon_preview.dart';
import '../domain/try_on_preset.dart';

final tryOnServiceProvider = Provider<TryOnService>((_) {
  return TryOnService();
});

class TryOnService {
  Future<TryOnPreview> generatePreview({
    required PetProfile pet,
    required TryOnPreset preset,
  }) async {
    final client = HttpClient();
    final imageBytes = await _loadPhotoBytes(pet.photoPath);
    final imageMimeType = _guessMimeType(pet.photoPath);

    try {
      final request = await client.postUrl(
        Uri.parse('$kApiBaseUrl/tryon-demo'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'petId': pet.id.startsWith('pet_') ? pet.id : null,
          'petName': pet.name,
          'breed': pet.breed,
          'weight': pet.weight,
          'neckGirth': pet.neckGirth,
          'chestGirth': pet.chestGirth,
          'backLength': pet.backLength,
          'photoPath': pet.photoPath,
          'imageBase64': imageBytes == null ? null : base64Encode(imageBytes),
          'imageMimeType': imageMimeType,
          'outfitName': preset.name,
          'category': preset.category,
          'color': preset.color,
          'pattern': preset.pattern,
          'brand': 'PetFit AI',
          'size': 'M',
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Try-on preview failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      return TryOnPreview.fromJson(payload);
    } finally {
      client.close(force: true);
    }
  }

  Future<List<int>?> _loadPhotoBytes(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }
    if (photoPath.startsWith('assets/')) {
      final data = await rootBundle.load(photoPath);
      return data.buffer.asUint8List();
    }
    return File(photoPath).readAsBytes();
  }

  String _guessMimeType(String? photoPath) {
    final normalized = (photoPath ?? '').toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/png';
  }
}
