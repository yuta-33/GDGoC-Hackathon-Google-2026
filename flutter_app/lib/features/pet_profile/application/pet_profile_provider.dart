import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pet_profile.dart';
import '../data/mock/mock_pet_data.dart';
import 'pet_profile_storage.dart';

final petProfileProvider =
    StateNotifierProvider<PetProfileNotifier, PetProfile>(
      (ref) => PetProfileNotifier(ref.read(petProfileStorageProvider)),
    );

class PetProfileNotifier extends StateNotifier<PetProfile> {
  PetProfileNotifier(this._storage) : super(defaultPetProfile) {
    _restore();
  }

  final PetProfileStorage _storage;

  Future<void> _restore() async {
    final savedProfile = await _storage.loadProfile();
    if (savedProfile == null) {
      return;
    }
    state = (savedProfile.photoPath == null || savedProfile.photoPath!.isEmpty)
        ? savedProfile.copyWith(photoPath: defaultPetPhotoAssetPath)
        : savedProfile;
  }

  Future<void> saveProfile(PetProfile next) async {
    state = next;
    await _storage.saveProfile(next);
  }
}
