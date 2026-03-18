class BreedBaseline {
  const BreedBaseline({
    required this.id,
    required this.displayName,
    required this.species,
    required this.weightKg,
    required this.neckGirthCm,
    required this.chestGirthCm,
    required this.backLengthCm,
  });

  final String id;
  final String displayName;
  final String species;
  final double weightKg;
  final double neckGirthCm;
  final double chestGirthCm;
  final double backLengthCm;

  factory BreedBaseline.fromJson(Map<String, dynamic> json) {
    return BreedBaseline(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      species: json['species'] as String? ?? 'dog',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      neckGirthCm: (json['neckGirthCm'] as num?)?.toDouble() ?? 0,
      chestGirthCm: (json['chestGirthCm'] as num?)?.toDouble() ?? 0,
      backLengthCm: (json['backLengthCm'] as num?)?.toDouble() ?? 0,
    );
  }
}
