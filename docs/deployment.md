# デプロイメント

このドキュメントでは、FavLogアプリケーションをGoogle Playストアにリリースするための設定と、CI/CDパイプラインの設定について説明します。

## 目次

- [Androidリリース署名設定](#androidリリース署名設定)
- [CI/CD（GitHub Actions）設定](#cicdgithub-actions設定)

## Androidリリース署名設定

Google PlayストアにリリースするためのAPKまたはApp Bundleをビルドするには、アプリケーションに署名する必要があります。

### 1. keystore（署名ファイル）の作成

まず、署名に使用する鍵ファイル（keystore）を生成します。`keytool`コマンドが実行できない場合は、JDKがインストールされ、その`bin`ディレクトリにPATHが通っていることを確認してください。

```bash
keytool -genkey -v -keystore my-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

このコマンドを実行すると、パスワードと組織情報の入力を求められます。ここで入力した**キーストアのパスワード**、**エイリアス名（`my-key-alias`）**、そして**エイリアスのパスワード**は後で必要になるため、安全な場所に保管してください。

生成された `my-release-key.keystore` ファイルは、ユーザーのホームディレクトリなど、プロジェクト外の安全な場所に保管することを推奨します。

### 2. `android/key.properties` の作成

プロジェクトの `android` ディレクトリに `key.properties` という名前のファイルを作成し、以下の内容を記述します。

```properties
storePassword=<キーストアのパスワード>
keyPassword=<エイリアスのパスワード>
keyAlias=<エイリアス名>
storeFile=<my-release-key.keystoreへの絶対パス>
```

**パスの記述に関する注意:**  
Windows環境でも、パスの区切り文字にはバックスラッシュ `\\` の代わりにフォワードスラッシュ `/` を使用することを推奨します。これにより、環境による問題を回避できます。

例: `storeFile=C:/Users/YourUser/keystores/my-release-key.keystore`

**セキュリティ:**  
このファイルにはパスワードなどの機密情報が含まれるため、Gitの追跡対象から除外する必要があります。プロジェクトのルートにある `.gitignore` ファイルに以下の行を追加してください。

```
/android/key.properties
```

### 3. `android/app/build.gradle.kts` の編集

`android/app/build.gradle.kts` ファイルを編集して、署名設定を読み込み、リリースビルドに適用します。

まず、ファイルの先頭に `java.io.FileInputStream` と `java.util.Properties` をインポートします。

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    // ...
}
```

次に、`plugins` ブロックの後に `key.properties` を読み込むロジックを追加します。

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

最後に、`android` ブロック内に `signingConfigs` を追加し、`buildTypes` の `release` ブロックを更新します。

```kotlin
android {
    // ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. リリースビルドの作成

すべての設定が完了したら、以下のコマンドで署名付きのリリースビルドを作成できます。

**App Bundle (Google Play推奨):**
```bash
flutter build appbundle --release
```

**APK:**
```bash
flutter build apk --release
```

成功すると、`build/app/outputs/bundle/release/app-release.aab` または `build/app/outputs/flutter-apk/app-release.apk` に成果物が生成されます。

## CI/CD（GitHub Actions）設定

このプロジェクトでは、GitHub Actions を使用してAndroidアプリのリリースビルドを自動化しています。

- **ワークフローファイル**: `.github/workflows/android_build.yml`
- **トリガー**: `workflow_dispatch` により、GitHubのActionsタブから手動で実行できます。

### 必要なシークレット

このワークフローを正しく動作させるには、GitHubリポジトリの `Settings > Secrets and variables > Actions` で以下のシークレットを設定する必要があります。

#### 1. Supabaseの接続情報

- `SUPABASE_URL`: SupabaseプロジェクトのURL。
- `SUPABASE_ANON_KEY`: SupabaseプロジェクトのAnon (public) キー。

#### 2. Androidの署名情報

- `ANDROID_KEYSTORE_BASE64`: 署名に使用するキーストアファイル (`my-release-key.keystore`) をBase64エンコードした文字列。
- `ANDROID_KEYSTORE_PASSWORD`: キーストアのパスワード。
- `ANDROID_KEY_PASSWORD`: キーストア内のエイリアスのパスワード。
- `ANDROID_KEY_ALIAS`: キーストアのエイリアス名。

`ANDROID_KEYSTORE_BASE64` の生成方法は以下の通りです（macOS/Linuxの場合）:
```bash
base64 -i my-release-key.keystore
```

生成された長い文字列をコピーして、`ANDROID_KEYSTORE_BASE64` シークレットの値として貼り付けます。

---

デプロイメント設定が完了したら、[メインREADME](../README.md)に戻ってください。
