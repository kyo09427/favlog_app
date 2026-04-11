import 'package:favlog_app/domain/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import "package:favlog_app/core/providers/supabase_provider.dart";

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseProvider));
});

final userProfileProvider = FutureProvider.family<Profile?, String>(
  (ref, userId) {
    final profileRepository = ref.watch(profileRepositoryProvider);
    return profileRepository.fetchProfile(userId);
  },
);
