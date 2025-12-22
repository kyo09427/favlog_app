import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../main.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SupabaseSettingsRepository(ref.watch(supabaseProvider));
});

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _supabaseClient;

  SupabaseSettingsRepository(this._supabaseClient);

  @override
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final response = await _supabaseClient
          .from('user_settings')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // 設定が存在しない場合はデフォルト設定を作成
        final defaultSettings = UserSettings.empty(userId);
        await createUserSettings(defaultSettings);
        return defaultSettings;
      }

      return UserSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user settings: $e');
    }
  }

  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      await _supabaseClient
          .from('user_settings')
          .update(settings.toJson())
          .eq('id', settings.id);
    } catch (e) {
      throw Exception('Failed to update user settings: $e');
    }
  }

  @override
  Future<void> createUserSettings(UserSettings settings) async {
    try {
      await _supabaseClient
          .from('user_settings')
          .insert(settings.toJson());
    } catch (e) {
      throw Exception('Failed to create user settings: $e');
    }
  }
}
