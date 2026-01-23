# Android Build Error Fix Roadmap - 2026-01-23

## 1. 現状の分析
### エラー内容
`AAPT: error: resource android:attr/lStar not found.`
このエラーは、`androidx.core:core:1.7.0` 以降のライブラリが内部的に `lStar` 属性（Android SDK 31で導入）を使用しているにもかかわらず、ビルドに使用している SDK バージョン（`compileSdkVersion`）がそれ未満（30以下）である場合に発生します。

### 直接の原因
GitHub Actions のログを見ると `Installing Android SDK Platform 28` とあり、一部のプラグイン（特にエラーが出ている `ota_update`）が古い SDK バージョンを要求してビルドされていることが推測されます。

---

## 2. 解決策
プロジェクト全体のビルド設定および、各プラグイン（サブプロジェクト）のビルド設定を強制的に最新の SDK に合わせることで解決します。

### 方針
1.  **`android/build.gradle.kts` の修正**:
    全サブプロジェクト（Flutterプラグイン）に対して、`compileSdk` を明示的に引き上げる設定を追加します。
2.  **`android/gradle.properties` の修正**:
    古いライブラリを AndroidX に対応させるための Jetifier を有効化します（念のため）。

---

## 3. 実行ロードマップ

- [x] **Step 1: 全サブプロジェクトの SDK バージョン強制統一**
    `android/build.gradle.kts` に、全プラグインの `compileSdk` を 36 に固定する処理を追加しました。これにより `lStar` 属性の欠落エラーを解消します。
- [x] **Step 2: Jetifier の有効化**
    `android/gradle.properties` に `android.enableJetifier=true` を追記し、古いライブラリの互換性を確保しました。
- [x] **Step 3: パッケージのアップグレード**
    `ota_update` ライブラリを `^6.0.0` から `^7.1.0` にアップグレードし、最新のビルド環境への対応を強化しました。
- [ ] **Step 4: 変更内容のプッシュと CI の確認**
    GitHub に変更をプッシュし、GitHub Actions のビルドが成功することを確認してください。

---

## 4. 修正内容の詳細

### `android/build.gradle.kts`
```kotlin
subprojects {
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(36)
        }
    }
}
```
※ `ota_update` 等の古いプラグインが独自の低い設定を持っていても、これで上書きされます。
