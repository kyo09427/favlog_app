import '../models/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getUserSettings(String userId);
  Future<void> updateUserSettings(UserSettings settings);
  Future<void> createUserSettings(UserSettings settings);
}
