class TryOnSizeChartEntry {
  const TryOnSizeChartEntry({
    required this.size,
    this.bustCm,
    this.backLengthCm,
    this.weightMinKg,
    this.weightMaxKg,
  });

  final String size;
  final int? bustCm;
  final int? backLengthCm;
  final double? weightMinKg;
  final double? weightMaxKg;
}

class TryOnPreset {
  const TryOnPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.pattern,
    required this.description,
    required this.badge,
    required this.platform,
    required this.sourceUrl,
    required this.sizeRange,
    required this.colors,
    required this.targetBreeds,
    required this.material,
    required this.thickness,
    required this.elasticity,
    required this.fastener,
    this.thumbnailUrl,
    this.sizeChart = const [],
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final String pattern;
  final String description;
  final String badge;
  final String platform;
  final String sourceUrl;
  final List<String> sizeRange;
  final List<String> colors;
  final List<String> targetBreeds;
  final String material;
  final String thickness;
  final String elasticity;
  final String fastener;
  final String? thumbnailUrl;
  final List<TryOnSizeChartEntry> sizeChart;
}
