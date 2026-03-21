import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/local_identity_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/closet_item.dart';

final closetServiceProvider = Provider<ClosetService>((_) {
  return ClosetService();
});

final closetItemsProvider = FutureProvider<List<ClosetItem>>((ref) {
  return ref
      .read(closetServiceProvider)
      .fetchClosetItems(
        ownerId: ref.read(localIdentityServiceProvider).getOwnerId(),
      );
});

class ClosetService {
  Future<List<ClosetItem>> fetchClosetItems({
    required Future<String> ownerId,
  }) async {
    final client = HttpClient();

    try {
      final resolvedOwnerId = await ownerId;
      final request = await client.getUrl(
        Uri.parse('$kApiBaseUrl/closet/items?ownerId=$resolvedOwnerId'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Closet fetch failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final items = payload['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ClosetItem.fromJson)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  Future<ClosetItem> createClosetItem({
    required Future<String> ownerId,
    required String name,
    required String category,
    required String color,
    required String size,
    required String brand,
    required List<String> seasonTags,
  }) async {
    final client = HttpClient();

    try {
      final resolvedOwnerId = await ownerId;
      final request = await client.postUrl(
        Uri.parse('$kApiBaseUrl/closet/items'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'ownerId': resolvedOwnerId,
          'name': name,
          'category': category,
          'color': color,
          'size': size,
          'brand': brand,
          'seasonTags': seasonTags,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.created) {
        throw HttpException(
          'Closet create failed with status ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final item = payload['item'] as Map<String, dynamic>?;
      if (item == null) {
        throw const FormatException('Missing closet item payload.');
      }
      return ClosetItem.fromJson(item);
    } finally {
      client.close(force: true);
    }
  }
}
