class ClosetItem {
  const ClosetItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.color,
    required this.size,
    required this.brand,
    required this.seasonTags,
    this.imageUrl,
    this.sourceUrl,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String color;
  final String size;
  final String brand;
  final List<String> seasonTags;
  final String? imageUrl;
  final String? sourceUrl;
  final String? createdAt;

  factory ClosetItem.fromJson(Map<String, dynamic> json) {
    return ClosetItem(
      id: json['clothingId'] as String? ?? json['itemId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? 'demo_user',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      color: json['color'] as String? ?? '',
      size: json['size'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      seasonTags: (json['seasonTags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      imageUrl: json['imageUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
