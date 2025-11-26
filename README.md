# FavLog (Favorite Log) アプリケーション README

## 概要

FavLogは、クローズドなコミュニティ（友人、家族、同僚など）内で商品やサービスのレビューを共有するためのAndroidアプリケーションです。「Trust Pick」をコンセプトに、検索アルゴリズムではなく、信頼できる関係に基づいた選択を支援します。

### 主要機能

*   **アカウント管理**: ユーザー登録、ログイン、ログアウト機能。
*   **レビュー投稿**: 商品名、URL、画像、カテゴリ（選択式）、サブカテゴリ（自由入力）、レビューテキスト、評価（星）を含むレビューを投稿。
*   **レビュー表示**: 投稿されたレビューがホーム画面に最新の1件のみ表示され、詳細画面ではすべてのレビューが表示されます。
*   **レビュー編集**: 作成者のみが自身のレビューを長押しで編集可能。編集時には画像やカテゴリなどの商品情報も更新できます。
*   **詳細画面**: 商品の全情報と、それに対するすべてのレビューを一覧表示。
*   **既存商品へのレビュー追加**: 詳細画面から、同一商品に対して別のユーザーがレビューを追加可能。
*   **カテゴリフィルタリング**: ホーム画面でカテゴリを選択してレビューを絞り込み表示。

## 技術スタック

*   **フロントエンド**: Flutter (Dart)
*   **バックエンド**: Supabase (PostgreSQL Database, Supabase Auth, Supabase Storage)
*   **バージョン管理**: Git, GitHub

## 環境セットアップ

### 前提条件

*   **Flutter SDK**: [Flutter公式サイト](https://flutter.dev/docs/get-started/install) の手順に従ってインストールしてください。
*   **Android Studio**: Androidエミュレータまたは実機でデバッグするために必要です。[Android Studio公式サイト](https://developer.android.com/studio) からダウンロード・インストールしてください。
*   **Git**: [Git公式サイト](https://git-scm.com/downloads) からインストールしてください。

### 1. リポジトリのクローン

```bash
git clone https://github.com/kyo09427/favlog_app.git
cd favlog_app
```

### 2. 依存関係のインストール

プロジェクトのルートディレクトリで以下のコマンドを実行し、必要なDartパッケージをインストールします。

```bash
flutter pub get
```

### 3. Flutter環境の確認

以下のコマンドを実行し、Flutter開発環境が正しく設定されていることを確認してください。

```bash
flutter doctor
```

問題がある場合は、出力される指示に従って修正してください。

## Supabase セットアップ

FavLogアプリケーションはバックエンドにSupabaseを使用します。以下の手順でSupabaseプロジェクトをセットアップしてください。

### 1. Supabaseプロジェクトの作成

1.  [Supabase公式サイト](https://supabase.com/) にアクセスし、アカウントを作成またはログインします。
2.  新しいプロジェクトを作成します。プロジェクトの地域は、ユーザーの所在地に近い場所を選択してください。

### 2. APIキーの設定

Supabaseプロジェクトの「Settings」>「API」セクションから、以下の情報を取得し、アプリケーションの `lib/main.dart` ファイルの `Supabase.initialize` メソッドに設定します。

*   **Project URL**: `https://YOUR_PROJECT_REF.supabase.co`
*   **Anon (public) key**: `eyJ...`

**`lib/main.dart` の関連箇所:**

```dart
// lib/main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // ここにあなたのProject URLを設定
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // ここにあなたのAnon (public) keyを設定
);
```

### 3. データベーススキーマの作成

Supabaseダッシュボードの「SQL Editor」で以下のSQLを実行し、`products` および `reviews` テーブルを作成し、行レベルセキュリティ (RLS) ポリシーを設定します。

#### `products` テーブル

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  url TEXT,
  name TEXT NOT NULL,
  category TEXT,
  subcategory TEXT, -- 追加: サブカテゴリ
  image_url TEXT
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view products" ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own products" ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own products" ON products
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products" ON products
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

#### `reviews` テーブル

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  review_text TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5)
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view all reviews" ON reviews
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own reviews" ON reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON reviews
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON reviews
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

### 4. Storage (ストレージ) の設定

Supabaseダッシュボードの「Storage」セクションで、画像アップロード用のバケットを作成し、RLSポリシーを設定します。

1.  「**New bucket**」をクリックし、バケット名を `product_images` とします。
2.  「**Public bucket**」のチェックボックスをオンにします。
3.  以下のSQLを「SQL Editor」で実行し、`product_images` バケットのRLSポリシーを設定します。

```sql
-- 'product_images'バケットのストレージポリシーを設定する

-- 認証されたユーザーが画像をアップロードできるようにするポリシー
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product_images' AND auth.uid() IS NOT NULL);

-- 誰でも画像を読み取れる（表示できる）ようにするポリシー
CREATE POLICY "Allow public access to images" ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product_images');
```

### 5. 認証設定 (Redirect URLs)

Supabaseプロジェクトの「Authentication」>「Settings」セクションで、「**Redirect URLs**」に以下のURLを追加します。これはメール認証後のリダイレクト先として必要です。

*   `io.supabase.flutterquickstart://login`

## アセットの設定

### 1. `assets/categories.json` の作成

プロジェクトのルートディレクトリ直下の `assets` フォルダ内に `categories.json` ファイルを作成し、以下の内容を記述します。

```json
{
  "categories": [
    "選択してください",
    "本",
    "家電",
    "食品",
    "ファッション",
    "ゲーム",
    "映画/音楽",
    "サービス",
    "その他"
  ]
}
```

### 2. `pubspec.yaml` の更新

`pubspec.yaml` ファイルの `flutter:` セクションに、作成した `assets` フォルダのパスを追加します。

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
```
**注意**: `assets/categories.json` を個別に指定することも可能ですが、`assets/` ディレクトリ全体を指定する方が一般的です。どちらを使用するかはプロジェクトの慣習に従ってください。

## アプリケーションの実行

上記すべてのセットアップが完了したら、以下のコマンドでアプリケーションを起動できます。

```bash
flutter run
```

エミュレータまたは接続されたデバイスでアプリケーションが起動し、ログイン画面が表示されます。

## テスト

*   **新規ユーザー登録**: メールアドレスとパスワードで新しいアカウントを作成し、メールを確認してください。
*   **ログイン**: 登録したアカウントでログインします。
*   **レビュー投稿**: ホーム画面の「+」ボタンから、商品名、URL、画像、**カテゴリ（選択式）**、**サブカテゴリ（自由入力）**、レビュー、評価を入力して投稿します。
*   **ホーム画面の表示**: 投稿したレビュー（商品情報と最新のレビュー1件、**カテゴリとサブカテゴリ**を含む）が表示されることを確認します。
*   **カテゴリ絞り込み**: AppBarのドロップダウンからカテゴリを選択し、レビューが正しく絞り込まれることを確認します。
*   **レビューの長押し編集**: 自身が投稿したレビューを長押しすると、編集画面に遷移し、内容を更新できることを確認します。
*   **レビューのタップ詳細表示**: レビューをタップすると、詳細画面に遷移し、すべてのレビューが表示されることを確認します。
*   **既存商品へのレビュー追加**: 詳細画面の「+」ボタンから、新しいレビューを追加し、詳細画面に反映されることを確認します。

## 今後の拡張

*   GitHub Pagesを用いたWeb版への対応
*   カテゴリ機能の強化（ネストされたサブカテゴリなど）
*   ユーザー検索・フォロー機能
*   レビューへのコメント機能
*   プッシュ通知の実装

---
This `README.md` should be placed in the root of your `favlog_app` directory.