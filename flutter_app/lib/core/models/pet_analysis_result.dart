class PetAnalysisResult {
  const PetAnalysisResult({
    required this.petType,
    required this.furColor,
    required this.bodySize,
    required this.styleTags,
  });

  final String petType;
  final String furColor;
  final String bodySize;
  final List<String> styleTags;

  factory PetAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PetAnalysisResult(
      petType: json['petType'] as String? ?? 'unknown',
      furColor: json['furColor'] as String? ?? 'unknown',
      bodySize: json['bodySize'] as String? ?? 'unknown',
      styleTags: (json['styleTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }
}
