/// バージョン情報モデル
///
/// GitHub上のversion.jsonから取得するアプリのバージョン情報を表現します。
class VersionInfo {
  /// バージョン番号（例: "1.7.5"）
  final String version;

  /// ビルド番号（例: 2601230）
  final int versionCode;

  /// APKダウンロードURL
  final String downloadUrl;

  /// リリースノート
  final String releaseNotes;

  /// サポートされる最小バージョン（これより古いバージョンは強制更新）
  final String minSupportedVersion;

  /// 強制更新フラグ
  final bool forceUpdate;

  const VersionInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.minSupportedVersion,
    required this.forceUpdate,
  });

  /// JSONからVersionInfoを生成
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      downloadUrl: json['downloadUrl'] as String,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      minSupportedVersion: json['minSupportedVersion'] as String? ?? '0.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }

  /// VersionInfoをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'minSupportedVersion': minSupportedVersion,
      'forceUpdate': forceUpdate,
    };
  }

  @override
  String toString() {
    return 'VersionInfo(version: $version, versionCode: $versionCode, forceUpdate: $forceUpdate)';
  }
}
