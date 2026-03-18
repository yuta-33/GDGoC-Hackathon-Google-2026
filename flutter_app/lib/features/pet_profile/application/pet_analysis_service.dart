import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/pet_analysis_result.dart';
import '../../../core/models/pet_profile.dart';

final petAnalysisServiceProvider = Provider<PetAnalysisService>((_) {
  return PetAnalysisService();
});

class PetAnalysisService {
  Future<PetAnalysisResult> analyzePet(PetProfile profile) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$kApiBaseUrl/analyze-pet'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'imageUrl': 'https://example.com/dummy-pet-image.png',
          'petName': profile.name,
          'breed': profile.breed,
          'weight': profile.weight,
          'neckGirth': profile.neckGirth,
          'chestGirth': profile.chestGirth,
          'backLength': profile.backLength,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Pet analysis failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final result = payload['result'] as Map<String, dynamic>?;
      if (result == null) {
        throw const FormatException('Missing result payload.');
      }

      return PetAnalysisResult.fromJson(result);
    } finally {
      client.close(force: true);
    }
  }
}
