import 'package:favlog_app/domain/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../main.dart'; // Import the main.dart to use supabaseProvider

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseProvider));
});

final userProfileProvider =
    FutureProvider.family.autoDispose<Profile?, String>((ref, userId) {
  // ref.keepAlive() を呼び出して、プロバイダの状態をキャッシュする
  ref.keepAlive();

  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchProfile(userId);
});