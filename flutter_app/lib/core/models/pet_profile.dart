class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.breed,
    required this.weight,
    required this.neckGirth,
    required this.chestGirth,
    required this.backLength,
    this.photoPath,
  });

  final String id;
  final String name;
  final String breed;
  final double weight;
  final double neckGirth;
  final double chestGirth;
  final double backLength;
  final String? photoPath;

  PetProfile copyWith({
    String? id,
    String? name,
    String? breed,
    double? weight,
    double? neckGirth,
    double? chestGirth,
    double? backLength,
    String? photoPath,
  }) {
    return PetProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      neckGirth: neckGirth ?? this.neckGirth,
      chestGirth: chestGirth ?? this.chestGirth,
      backLength: backLength ?? this.backLength,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
