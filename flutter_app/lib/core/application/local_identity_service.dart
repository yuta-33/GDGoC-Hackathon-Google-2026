import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localIdentityServiceProvider = Provider<LocalIdentityService>((_) {
  return LocalIdentityService();
});

class LocalIdentityService {
  static const _ownerIdKey = 'local_owner_id';

  Future<String> getOwnerId() async {
    final preferences = await SharedPreferences.getInstance();
    final existingId = preferences.getString(_ownerIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final ownerId = 'owner_${DateTime.now().microsecondsSinceEpoch}';
    await preferences.setString(_ownerIdKey, ownerId);
    return ownerId;
  }
}
