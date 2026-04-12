import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;

class Constants {
  static const String siteUrl = 'https://favlog.okasis.win/';
  static const String customScheme = 'com.example.favlog_app://';

  /// プラットフォームに応じたリダイレクトURLを返します。
  /// Webの場合は HTTPS URL、それ以外（Android/iOS）の場合はカスタムURLスキームを返します。
  static String getRedirectUrl() {
    return kIsWeb ? siteUrl : customScheme;
  }
}

/// アプリ共通カラー定数
class AppColors {
  // --- ブランドカラー ---
  static const Color primary = Color(0xFF13EC5B);
  static const Color primaryMuted = Color(0xFF9DB9A6);
  static const Color calmGreen = Color(0xFF22A06B);
  static const Color deepGreen = Color(0xFF1B5E20);

  // --- 背景・サーフェス ---
  static const Color backgroundDark = Color(0xFF102216);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color cardDark = Color(0xFF1C1C1E);

  // --- テキスト ---
  static const Color textLight = Color(0xFF1F2937);
  static const Color subtextLight = Color(0xFF6B7280);
  static const Color subtextDark = Color(0xFF9CA3AF);

  // --- 区切り線・ボーダー ---
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);

  // --- ナビゲーション ---
  static const Color selectedNav = Color(0xFF4CAF50);

  // --- その他 ---
  static const Color star = Color(0xFFFBBF24);
}

/// アプリ動作に関わる数値定数
class AppLimits {
  // キャッシュ
  static const Duration homeCacheDuration = Duration(seconds: 30);

  // 画像
  static const int reviewImageMaxCount = 3;

  // スクロール
  static const double scrollLoadThreshold = 0.9;

  // 検索履歴
  static const int searchHistoryMaxCount = 10;
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
