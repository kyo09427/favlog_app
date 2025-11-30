import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabaseClient;

  SupabaseProfileRepository(this._supabaseClient);

  @override
  Future<Profile?> fetchProfile(String userId) async {
    final data = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle(); // Use maybeSingle directly

    if (data != null) {
      return Profile.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _supabaseClient.from('profiles').upsert(
      profile.toJson(),
      onConflict: 'id', // Use 'id' as the conflict target for upsert
    );
    // If no exception is thrown, it means success.
  }
}