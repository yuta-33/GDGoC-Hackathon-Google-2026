import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/saved_look.dart';

final savedLooksServiceProvider = Provider<SavedLooksService>((_) {
  return SavedLooksService();
});

final savedLooksProvider = FutureProvider<List<SavedLook>>((ref) {
  return ref.read(savedLooksServiceProvider).fetchSavedLooks();
});

class SavedLooksService {
  Future<List<SavedLook>> fetchSavedLooks({String? petId}) async {
    final client = HttpClient();

    try {
      final suffix = petId == null || petId.isEmpty ? '' : '?petId=$petId';
      final request = await client.getUrl(
        Uri.parse('$kApiBaseUrl/saved-looks$suffix'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Saved looks fetch failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final items = payload['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(SavedLook.fromJson)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  Future<SavedLook> createSavedLook({
    required String petId,
    required List<String> clothingIds,
    String? memo,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$kApiBaseUrl/saved-looks'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'petId': petId,
          'clothingIds': clothingIds,
          if (memo != null && memo.isNotEmpty) 'memo': memo,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.created) {
        throw HttpException(
          'Saved look create failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final item = payload['item'] as Map<String, dynamic>?;
      if (item == null) {
        throw const FormatException('Missing saved look payload.');
      }
      return SavedLook.fromJson(item);
    } finally {
      client.close(force: true);
    }
  }
}
