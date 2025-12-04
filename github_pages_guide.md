# FavLog - GitHub Pages公開ガイド

## 概要

FavLogをGitHub Pagesで公開するには、Flutter Webアプリケーションとしてビルドし、静的ファイルをGitHub Pagesで公開する必要があります。このガイドでは、その手順を段階別に説明します。

---

## フェーズ1: Flutter Web環境のセットアップ

### 1.1 Chrome Devtoolsのインストール確認

```bash
flutter doctor
```

**確認ポイント**:
- Chrome がインストール済みであることを確認（Flutter Webビルド時に必要）

### 1.2 Web対応の有効化

```bash
flutter config --enable-web
```

### 1.3 Web用依存関係の追加

```bash
flutter pub add flutter_web_plugins
```

---

## フェーズ2: Webビルド向けのコード修正

### 2.1 Supabase初期化の修正

`lib/main.dart` の Supabase 初期化部分を修正し、Web環境でも正しく動作するようにします。

**注意**: Web環境では `flutter_dotenv` のファイルパスの解決が異なるため、環境変数を別途処理する必要があります。

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 環境変数の読み込み
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Web環境では .env の読み込みがスキップされる可能性
    print('Warning: Failed to load .env file: $e');
  }

  // Supabase初期化
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'YOUR_FALLBACK_URL',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_FALLBACK_KEY',
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

### 2.2 プラットフォーム固有の機能への対応

**ImagePickerのWeb対応確認**:
`image_picker` パッケージはWeb環境でも動作しますが、セキュリティ上の制限があります。以下を確認します：

- `web/index.html` にて、`<input type="file">` が許可されていることを確認
- iOS/Androidと異なる挙動（カメラが使用不可など）に対応

**flutter_image_compressのWeb対応**:
`flutter_image_compress` はネイティブプラットフォーム向けです。Web向けには代替実装が必要です。

```dart
// lib/core/services/image_compressor.dart を修正

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressor {
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    // Web環境とネイティブ環境を判定
    if (kIsWeb) {
      return _compressImageWeb(imageBytes, maxWidth, maxHeight, quality);
    } else {
      return _compressImageNative(imageBytes, maxWidth, maxHeight, quality);
    }
  }

  Future<Uint8List> _compressImageWeb(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      final resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      print('Error compressing image on web: $e');
      return imageBytes;
    }
  }

  Future<Uint8List> _compressImageNative(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    // ネイティブ環境では flutter_image_compress を使用
    // 既存実装を継続
    return imageBytes;
  }
}
```

### 2.3 IndexedDB対応（オプション）

オフライン機能が必要な場合は、`hive_web` または `shared_preferences` をWeb対応させます。

```bash
flutter pub add shared_preferences_web
```

---

## フェーズ3: GitHub Pages用の設定

### 3.1 GitHub リポジトリの設定

**既に GitHub にプッシュ済みの場合:**

1. リポジトリの「Settings」 > 「Pages」を開く
2. 「Build and deployment」で以下を設定：
   - Source: `Deploy from a branch`
   - Branch: `main` (または任意のブランチ), `/docs` フォルダ
   - または Source: `GitHub Actions` を使用

### 3.2 ビルドスクリプトの作成

プロジェクトルートに `build_web.sh` を作成：

```bash
#!/bin/bash
set -e

echo "Building Flutter Web..."
flutter clean
flutter pub get
flutter build web --release --web-renderer html

echo "Preparing for GitHub Pages..."
mkdir -p docs
rm -rf docs/*
cp -r build/web/* docs/

echo "Build complete! Files ready in docs/ directory"
```

実行権限を付与：

```bash
chmod +x build_web.sh
```

### 3.3 GitHub Actions ワークフローの作成

`.github/workflows/deploy.yml` を作成：

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.1'
        channel: 'stable'

    - name: Get dependencies
      run: flutter pub get

    - name: Enable web
      run: flutter config --enable-web

    - name: Build web
      run: flutter build web --release --web-renderer html

    - name: Prepare docs directory
      run: |
        mkdir -p docs
        rm -rf docs/*
        cp -r build/web/* docs/

    - name: Commit and push
      run: |
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git add docs/
        git commit -m "Deploy: Update web build [skip ci]" || true
        git push

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

---

## フェーズ4: Web向けのUI/UX調整

### 4.1 index.html の更新

`web/index.html` を修正し、メタタグやスタイルを最適化：

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="description" content="FavLog - Trust Pick レビュー共有アプリケーション">
    
    <!-- Web App Meta Tags -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#2196F3">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="FavLog">
    
    <title>FavLog - Trust Pick レビュー共有</title>
    
    <link rel="icon" type="image/png" href="favicon.png">
    <link rel="manifest" href="manifest.json">
    
    <style>
        html, body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        #app-container {
            width: 100%;
            height: 100%;
        }
        
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
    </style>
</head>
<body>
    <div class="loading" id="loading">
        <div style="color: white; text-align: center;">
            <p>Loading FavLog...</p>
        </div>
    </div>
    
    <script src="flutter.js" defer></script>
    <script>
        window.addEventListener('load', function(ev) {
            document.getElementById('loading').style.display = 'none';
            _flutter.loader.loadEntrypoint({
                serviceWorkerVersion: null,
                onEntrypointLoaded: function(engineInitializer) {
                    engineInitializer.initializeEngine().then(function(appRunner) {
                        appRunner.runApp();
                    });
                }
            });
        });
    </script>
</body>
</html>
```

### 4.2 PWA対応 (オプション)

`web/manifest.json` を作成：

```json
{
  "name": "FavLog",
  "short_name": "FavLog",
  "description": "Trust Pick - クローズドなコミュニティ向けレビュー共有アプリケーション",
  "start_url": "/favlog_app/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## フェーズ5: ビルドとデプロイ

### 5.1 ローカルでのビルドとテスト

```bash
# ビルド
./build_web.sh

# ローカルテスト（Webサーバー起動）
python -m http.server 8000 --directory docs
# またはNode.jsの場合
# npx http-server docs -p 8000
```

ブラウザで `http://localhost:8000` にアクセスして動作確認。

### 5.2 GitHub にプッシュ

```bash
git add .github/workflows/deploy.yml docs/
git commit -m "feat: Add GitHub Pages deployment workflow"
git push origin main
```

GitHub Actions が自動実行され、デプロイが完了します。

### 5.3 URL設定

GitHub Pages のデプロイ完了後、リポジトリの Settings > Pages で確認したURLが公開アドレスになります。

典型的なURL: `https://kyo09427.github.io/favlog_app/`

---

## フェーズ6: 本番運用とメンテナンス

### 6.1 CORS設定の確認

Supabase APIへのアクセス時にCORSエラーが発生する場合、Supabase ダッシュボードで以下を設定：

Settings > API > CORS Configuration:
```
https://kyo09427.github.io
```

### 6.2 環境変数の安全な管理

Web公開時には、機密情報（Anonキー）が見えてしまう可能性があります。対策：

1. **Supabase RLS の強化**: Row Level Security ポリシーで徹底的に保護
2. **API レート制限**: Supabase のレート制限設定を有効化
3. **バックエンド API の構築** (今後の拡張): 機密キーをバックエンドに隠す

### 6.3 トラッキング (オプション)

Google Analytics などを追加する場合、`web/index.html` に追記：

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

---

## トラブルシューティング

### Q1: ビルド時に「Cannot find module」エラーが出る

**A**: キャッシュをクリアしてリビルド：
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Q2: Supabase への接続がタイムアウトする

**A**: `.env` ファイルの設定を確認し、SUPABASE_URL と SUPABASE_ANON_KEY が正しいか確認してください。Web環境では、API キーが明示的に公開されるため、RLS設定に依存します。

### Q3: 画像が表示されない

**A**: ローカルパスではなく、Supabase の公開URL (`https://...supabase.co/...`) を使用していることを確認してください。

### Q4: GitHub Pages の公開アドレスが間違っている

**A**: `pubspec.yaml` で設定されている `web:` セクションの `homePage` を確認：
```yaml
web:
  generate: true
```

必要に応じて、以下を明示的に設定：
```yaml
web:
  homePage: "https://kyo09427.github.io/favlog_app/"
```

---

## 次のステップ

1. **フェーズ1～3を実装**: Flutter Web環境とGitHub Pages の基本設定
2. **フェーズ4を実装**: UI/UXの調整と PWA対応
3. **フェーズ5でビルド・テスト**: ローカルでの動作確認後にデプロイ
4. **フェーズ6で運用**: CORS、環境変数、トラッキングなどの本番対応

---

## 参考リンク

- [Flutter Web documentation](https://flutter.dev/docs/get-started/web)
- [GitHub Pages documentation](https://pages.github.com/)
- [GitHub Actions deployment guide](https://docs.github.com/en/actions/deployment/about-deployments/deploying-with-github-actions)
- [Supabase CORS configuration](https://supabase.com/docs/guides/api/cors)