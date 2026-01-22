import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/version_info.dart';

/// アプリのバージョン更新をチェックするサービス
///
/// GitHub上のversion.jsonを取得し、現在のバージョンと比較します。
class UpdateService {
  /// version.jsonのURL
  ///
  /// GitHub Pagesにデプロイされたversion.jsonを参照します。
  static const String versionJsonUrl =
      'https://kyo09427.github.io/favlog_app/version.json';

  /// 最終チェック日時を保存するキー
  static const String _lastCheckKey = 'last_update_check';

  /// チェック間隔（ミリ秒）- デフォルト24時間
  static const int checkIntervalMs = 24 * 60 * 60 * 1000;

  /// 現在のアプリバージョンを取得
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 現在のビルド番号を取得
  Future<int> getCurrentBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 0;
  }

  /// GitHub上の最新バージョン情報を取得
  Future<VersionInfo?> fetchLatestVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse(versionJsonUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('バージョン情報の取得がタイムアウトしました');
            },
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VersionInfo.fromJson(json);
      } else {
        throw Exception('バージョン情報の取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching version info: $e');
      return null;
    }
  }

  /// 更新が利用可能かチェック
  ///
  /// 現在のビルド番号と最新のビルド番号を比較します。
  Future<bool> isUpdateAvailable() async {
    final latestVersion = await fetchLatestVersion();
    if (latestVersion == null) {
      return false;
    }

    final currentBuildNumber = await getCurrentBuildNumber();
    return latestVersion.versionCode > currentBuildNumber;
  }

  /// 強制更新が必要かチェック
  ///
  /// 以下の条件で強制更新が必要と判定します:
  /// 1. version.jsonのforceUpdateフラグがtrue
  /// 2. 現在のバージョンがminSupportedVersionより古い
  Future<bool> isForceUpdateRequired() async {
    final latestVersion = await fetchLatestVersion();
    if (latestVersion == null) {
      return false;
    }

    // forceUpdateフラグがtrueの場合
    if (latestVersion.forceUpdate) {
      return true;
    }

    // 現在のバージョンがminSupportedVersionより古い場合
    final currentVersion = await getCurrentVersion();
    return _compareVersions(currentVersion, latestVersion.minSupportedVersion) <
        0;
  }

  /// バージョンチェックを実行すべきかどうか
  ///
  /// 最終チェックから指定時間（デフォルト24時間）経過している場合にtrueを返します。
  Future<bool> shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckMs = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    return (now - lastCheckMs) > checkIntervalMs;
  }

  /// 最終チェック日時を更新
  Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// バージョン文字列を比較
  ///
  /// 戻り値:
  /// - 負の値: version1 < version2
  /// - 0: version1 == version2
  /// - 正の値: version1 > version2
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 != v2) {
        return v1 - v2;
      }
    }

    return 0;
  }
}
