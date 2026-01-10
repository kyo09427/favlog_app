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
      return Profile.fromJson(data);
    }
    return null;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    try {
      // まず既存のプロフィールを確認
      final existing = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', profile.id)
          .maybeSingle();

      if (existing != null) {
        // 既存プロフィールがある場合は更新
        // 明示的に必要なフィールドのみを送信
        final updateData = {
          'username': profile.username,
          'avatar_url': profile.avatarUrl,
        };
        
        await _supabaseClient
            .from('profiles')
            .update(updateData)
            .eq('id', profile.id);
      } else {
        // 新規作成
        await _supabaseClient
            .from('profiles')
            .insert(profile.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }
}