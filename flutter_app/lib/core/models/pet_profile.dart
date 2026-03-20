class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.breed,
    required this.weight,
    this.weightUnit = 'KG',
    required this.neckGirth,
    required this.chestGirth,
    required this.backLength,
    this.photoPath,
  });

  final String id;
  final String name;
  final String breed;
  final double weight;
  final String weightUnit;
  final double neckGirth;
  final double chestGirth;
  final double backLength;
  final String? photoPath;

  PetProfile copyWith({
    String? id,
    String? name,
    String? breed,
    double? weight,
    String? weightUnit,
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
      weightUnit: weightUnit ?? this.weightUnit,
      neckGirth: neckGirth ?? this.neckGirth,
      chestGirth: chestGirth ?? this.chestGirth,
      backLength: backLength ?? this.backLength,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'weight': weight,
      'weightUnit': weightUnit,
      'neckGirth': neckGirth,
      'chestGirth': chestGirth,
      'backLength': backLength,
      'photoPath': photoPath,
    };
  }

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'] as String? ?? '1',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      weightUnit: json['weightUnit'] as String? ?? 'KG',
      neckGirth: (json['neckGirth'] as num?)?.toDouble() ?? 0,
      chestGirth: (json['chestGirth'] as num?)?.toDouble() ?? 0,
      backLength: (json['backLength'] as num?)?.toDouble() ?? 0,
      photoPath: json['photoPath'] as String?,
    );
  }
}
