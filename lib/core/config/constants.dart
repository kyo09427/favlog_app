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

class ValidationLimits {
  // 商品
  static const int productNameMaxLength = 100;
  static const int productUrlMaxLength = 2048;

  // タグ
  static const int tagMaxLength = 30;
  static const int tagMaxCount = 10;

  // レビュー
  static const int reviewTextMaxLength = 2000;

  // コメント
  static const int commentTextMaxLength = 500;
}
