import 'closet_item.dart';

class SavedLook {
  const SavedLook({
    required this.id,
    required this.petId,
    required this.clothingIds,
    required this.itemCount,
    required this.items,
    this.thumbnailUrl,
    this.memo,
    this.createdAt,
  });

  final String id;
  final String petId;
  final List<String> clothingIds;
  final int itemCount;
  final List<ClosetItem> items;
  final String? thumbnailUrl;
  final String? memo;
  final String? createdAt;

  factory SavedLook.fromJson(Map<String, dynamic> json) {
    final clothingIds = (json['clothingIds'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ClosetItem.fromJson)
        .toList(growable: false);

    return SavedLook(
      id: json['lookId'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      clothingIds: clothingIds,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? items.length,
      items: items,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
