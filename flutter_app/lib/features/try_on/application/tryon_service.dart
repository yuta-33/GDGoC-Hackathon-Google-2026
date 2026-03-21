import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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
    final cacheKey = _cacheKeyFor(pet: pet, preset: preset);
    final cachedPreview = await _readCachedPreview(cacheKey);
    if (cachedPreview != null) {
      return cachedPreview;
    }

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
      await _writeCachedPreview(cacheKey, payload);
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

  String _cacheKeyFor({required PetProfile pet, required TryOnPreset preset}) {
    final seed = '${pet.id}|${pet.photoPath}|${preset.id}';
    var hash = 17;
    for (final unit in utf8.encode(seed)) {
      hash = 37 * hash + unit;
    }
    return hash.abs().toString();
  }

  Future<TryOnPreview?> _readCachedPreview(String cacheKey) async {
    final cacheFile = await _cacheFileFor(cacheKey);
    if (!await cacheFile.exists()) {
      return null;
    }

    try {
      final payload = jsonDecode(await cacheFile.readAsString());
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      return TryOnPreview.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedPreview(
    String cacheKey,
    Map<String, dynamic> payload,
  ) async {
    final cacheFile = await _cacheFileFor(cacheKey);
    await cacheFile.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<File> _cacheFileFor(String cacheKey) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${baseDir.path}/tryon_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$cacheKey.json');
  }
}
