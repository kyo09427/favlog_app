import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  static const String siteUrl = 'https://favlog.okasis.win/';
  static const String customScheme = 'com.example.favlog_app://';
  static const String discordTargetGuildId = String.fromEnvironment(
    'DISCORD_TARGET_GUILD_ID',
    defaultValue: '',
  );

  /// プラットフォームに応じたリダイレクトURLを返します。
  /// Webの場合は HTTPS URL、それ以外（Android/iOS）の場合はカスタムURLスキームを返します。
  static String getRedirectUrl() {
    return kIsWeb ? siteUrl : customScheme;
  }
}
