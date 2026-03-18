import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/breed_baseline.dart';

final breedBaselineServiceProvider = Provider<BreedBaselineService>((_) {
  return BreedBaselineService();
});

final breedBaselinesProvider = FutureProvider<List<BreedBaseline>>((ref) async {
  return ref.read(breedBaselineServiceProvider).fetchBreedBaselines();
});

class BreedBaselineService {
  Future<List<BreedBaseline>> fetchBreedBaselines() async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse('$kApiBaseUrl/breeds'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Breed baseline fetch failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final items = payload['items'] as List<dynamic>? ?? const <dynamic>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(BreedBaseline.fromJson)
          .toList();
    } finally {
      client.close(force: true);
    }
  }
}
