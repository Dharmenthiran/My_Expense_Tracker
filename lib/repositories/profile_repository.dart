import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../viewmodels/providers.dart';

class ProfileRepository {
  final AppDatabase _db;

  ProfileRepository(this._db);

  Future<Profile?> getProfile() async {
    final profiles = await _db.select(_db.profiles).get();
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<void> saveProfile(ProfilesCompanion profile) async {
    final existing = await getProfile();
    if (existing == null) {
      await _db.into(_db.profiles).insert(profile);
    } else {
      await _db.update(_db.profiles).replace(profile.copyWith(id: Value(existing.id)));
    }
  }

  Stream<Profile?> watchProfile() {
    return _db.select(_db.profiles).watchSingleOrNull();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProfileRepository(db);
});

final profileProvider = StreamProvider<Profile?>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchProfile();
});
