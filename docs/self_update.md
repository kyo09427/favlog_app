# セルフアップデート機能（Self-Update Service）

FavLogアプリは、GitHub Releases経由で配布されるAPKをアプリ内から自動的に更新する機能を備えています。

## 概要

この機能は、GitHub Pagesに配置された `version.json` を定期的にチェックし、新しいバージョンが利用可能な場合にユーザーに通知し、APKのダウンロードとインストールを行います。

## 技術スタック

- **package_info_plus**: 現在のアプリバージョン情報の取得
- **http**: バージョン情報のJSONファイルの取得
- **ota_update**: APKのダウンロード、進捗管理、インストーラーの起動
- **GitHub Actions**: リリースビルド時に `version.json` を自動生成しデプロイ

## システム構成

1. **GitHub Actions (`web_apk_build.yml`)**:
   - `workflow_dispatch` (手動実行) 時にAPKをビルドし、Releaseを作成。
   - バージョン名、ビルド番号、APKのダウンロードURL、コミットログを含む `version.json` を生成。
   - `build/web` に配置し、GitHub Pages (GitHub IO) にデプロイ。

2. **UpdateService (`lib/services/update_service.dart`)**:
   - `https://kyo09427.github.io/favlog_app/version.json` を取得。
   - 現在のビルド番号 (`versionCode`) と比較。
   - 強制アップデート (`forceUpdate`) または最小サポートバージョン (`minSupportedVersion`) のチェック。

3. **ApkInstaller (`lib/services/apk_installer.dart`)**:
   - `ota_update` をラップし、ダウンロード進捗やステータスをストリームで提供。

4. **UI Components**:
   - `UpdateDialog`: アップデートの通知とリリースノートの表示。
   - `DownloadProgressDialog`: ダウンロード中の進捗表示。

## 実装の詳細

### 起動時チェック (`main.dart`)
アプリ起動時に24時間間隔で自動チェックを行います。

### 手動チェック (`settings_screen.dart`)
設定画面の「アップデートを確認」からいつでもチェック可能です。

## Android固有の設定

`AndroidManifest.xml` に以下の権限が追加されています：
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```
ユーザーは初回インストール時に、このアプリに対して「不明なアプリのインストール」の許可を与える必要があります（`ota_update` が自動的にシステム設定へ誘導します）。

## リリース手順

1. `pubspec.yaml` のバージョンは、GitHub Actions の `workflow_dispatch` 入力によって上書きされます。
2. GitHub のワークフロー「Build Android APK + Deploy Web」を手動で実行します。
3. バージョン番号（例: `1.8.0`）を入力して実行します。
4. ビルド完了後、自動的に Release が作成され、`version.json` が更新されます。

## 注意事項

- **署名の一致**: アップデート前後のAPKは同じキーストアで署名されている必要があります。不一致の場合、Androidシステムがインストールを拒否します。
- **ネットワーク環境**: APKは数MB〜数十MBのサイズがあるため、Wi-Fi環境での実行を推奨します。
