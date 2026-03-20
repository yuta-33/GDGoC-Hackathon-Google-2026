import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/pet_profile.dart';

final petProfileStorageProvider = Provider<PetProfileStorage>((_) {
  return PetProfileStorage();
});

class PetProfileStorage {
  static const _profileKey = 'pet_profile';

  Future<PetProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PetProfile.fromJson(json);
  }

  Future<void> saveProfile(PetProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
