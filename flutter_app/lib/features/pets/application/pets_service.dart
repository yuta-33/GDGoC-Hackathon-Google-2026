import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/pet_profile.dart';
import '../../pet_profile/data/mock/mock_pet_data.dart';

final petsServiceProvider = Provider<PetsService>((_) {
  return PetsService();
});

final petsProvider = FutureProvider<List<PetProfile>>((ref) {
  return ref.read(petsServiceProvider).fetchPets();
});

class PetsService {
  Future<List<PetProfile>> fetchPets() async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse('$kApiBaseUrl/pets'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Pets fetch failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final items = payload['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(_profileFromApi)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  Future<PetProfile> savePet(PetProfile profile) async {
    final client = HttpClient();
    final isExistingPet = profile.id.startsWith('pet_');

    try {
      final request = isExistingPet
          ? await client.putUrl(Uri.parse('$kApiBaseUrl/pets/${profile.id}'))
          : await client.postUrl(Uri.parse('$kApiBaseUrl/pets'));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'petName': profile.name,
          'breed': profile.breed,
          'weight': profile.weight,
          'neckGirth': profile.neckGirth,
          'chestGirth': profile.chestGirth,
          'backLength': profile.backLength,
          'photoPath': profile.photoPath,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.created) {
        throw HttpException(
          'Pet save failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final item = payload['item'] as Map<String, dynamic>?;
      if (item == null) {
        throw const FormatException('Missing pet item payload.');
      }

      return _profileFromApi(item).copyWith(
        weightUnit: profile.weightUnit,
        photoPath: item['imageUrl'] as String? ?? profile.photoPath,
      );
    } finally {
      client.close(force: true);
    }
  }

  PetProfile _profileFromApi(Map<String, dynamic> json) {
    return PetProfile(
      id: json['petId'] as String? ?? '1',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      weightUnit: 'KG',
      neckGirth: (json['neckGirthCm'] as num?)?.toDouble() ?? 0,
      chestGirth: (json['chestGirthCm'] as num?)?.toDouble() ?? 0,
      backLength: (json['backLengthCm'] as num?)?.toDouble() ?? 0,
      photoPath: json['imageUrl'] as String? ?? defaultPetPhotoAssetPath,
    );
  }
}
