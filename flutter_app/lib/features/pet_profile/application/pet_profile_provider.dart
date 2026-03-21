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
    if (_isLegacyDemoProfile(savedProfile)) {
      await _storage.clearProfile();
      state = defaultPetProfile;
      return;
    }
    state = savedProfile;
  }

  Future<void> saveProfile(PetProfile next) async {
    state = next;
    await _storage.saveProfile(next);
  }

  Future<void> resetProfile() async {
    state = defaultPetProfile;
    await _storage.clearProfile();
  }

  bool _isLegacyDemoProfile(PetProfile profile) {
    return profile.name == 'Buddy' &&
        profile.breed == 'Golden Retriever' &&
        profile.weight == 28.5 &&
        profile.neckGirth == 42 &&
        profile.chestGirth == 68 &&
        profile.backLength == 55;
  }
}
