# FavLog (Favorite Log) アプリケーション README

## 概要

FavLogは、クローズドなコミュニティ（友人、家族、同僚など）内で商品やサービスのレビューを共有するためのAndroidアプリケーションです。「Trust Pick」をコンセプトに、検索アルゴリズムではなく、信頼できる関係に基づいた選択を支援します。

### 主要機能

*   **アカウント管理**: ユーザー登録、ログイン、ログアウト機能。メール認証フローの改善（未確認ユーザーへの警告表示、リセンドメール機能）。**JWT有効期限切れ時の自動ログアウトと再認証誘導**。
*   **レビュー投稿**: 商品名、URL、画像、カテゴリ（ChoiceChipによる視覚的選択）、サブカテゴリ（自由入力、**オートコンプリート候補表示**）、レビューテキスト、評価（星）を含むレビューを投稿。**画像アップロード時の自動圧縮**。
*   **レビュー表示**: 投稿されたレビューがホーム画面に最新の1件のみ表示され、詳細画面ではすべてのレビューが表示されます。**ローディング状態の改善（Shimmer効果）**。
*   **レビュー編集**: 作成者のみが自身のレビューを長押しで編集可能。編集時には画像やカテゴリなどの商品情報も更新できます。製品・レビュー所有者チェックの強化。
*   **詳細画面**: 商品の全情報と、それに対するすべてのレビューを一覧表示。
*   **既存商品へのレビュー追加**: 詳細画面から、同一商品に対して別のユーザーがレビューを追加可能。
*   **カテゴリフィルタリング**: ホーム画面でカテゴリを選択してレビューを絞り込み表示（**「すべて」のフィルタリングロジック改善**）。
*   **軽量検索機能**: ホーム画面で商品名による検索が可能（**デバウンス処理付き**）。
*   **画像表示の最適化**: **画像キャッシュ（CachedNetworkImage）**、読み込み中の**プレースホルダー**、エラー時の**画像表示**。
*   **レスポンシブデザイン**: モバイル・タブレット・Webなど、デバイスの画面幅に応じた最適なレイアウトを提供。
*   **統一されたエラーハンドリング**: ネットワークエラー、認証エラーなど、エラーの種類に応じた適切なメッセージを統一的なダイアログで表示。

## 技術スタック

*   **フロントエンド**: Flutter (Dart), **Riverpod** (状態管理), **cached_network_image** (画像キャッシュ), **shimmer** (ローディングエフェクト)
*   **バックエンド**: Supabase (PostgreSQL Database, Supabase Auth, Supabase Storage)
*   **ユーティリティ**: **flutter_dotenv** (環境変数管理), **image** (画像処理)
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

Supabaseプロジェクトの「Settings」>「API」セクションから、以下の情報を取得し、プロジェクトルートにある `.env` ファイルに設定します。

*   **Project URL**: `https://YOUR_PROJECT_REF.supabase.co`
*   **Anon (public) key**: `eyJ...`

`.env` ファイルの例:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

**重要**: `.env` ファイルはGitの管理下に置かないよう、`.gitignore` に追加してください。

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
    "すべて",
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
**注意**: ホーム画面でのフィルタリングのために、プログラムで最初の項目として "すべて" が追加されます。レビュー追加・編集画面では、ユーザーにカテゴリ選択を促すヒントが表示されます。

### 2. `.env` ファイルの作成

プロジェクトのルートディレクトリに `.env` ファイルを作成し、SupabaseのAPIキー（`SUPABASE_URL` と `SUPABASE_ANON_KEY`）を記述します。

### 3. `pubspec.yaml` の更新

`pubspec.yaml` ファイルの `flutter:` セクションに、作成した `assets` フォルダと `.env` ファイルのパスを追加します。

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
    - .env
```
**注意**: `assets/categories.json` を個別に指定することも可能ですが、`assets/` ディレクトリ全体を指定する方が一般的です。どちらを使用するかはプロジェクトの慣習に従ってください。

## アプリケーションの実行

上記すべてのセットアップが完了したら、以下のコマンドでアプリケーションを起動できます。

```bash
flutter run
```

エミュレータまたは接続されたデバイスでアプリケーションが起動し、ログイン画面が表示されます。

## テスト

主要な機能が正しく動作するか、以下の点を確認してください。

*   **新規ユーザー登録**: メールアドレスとパスワードで新しいアカウントを作成します。
    *   登録後、通常のホーム画面ではなく**メールアドレス確認画面**（EmailVerificationScreen）が表示されることを確認します。
    *   確認画面から「認証メールを再送する」ボタンを押し、成功メッセージが表示されることを確認します。
*   **既存ユーザー（メール未確認）**: メール未確認のユーザーでログインした場合、**メールアドレス確認画面**が表示されることを確認します。
*   **既存ユーザー（メール確認済み）**: メール確認済みのユーザーでログインした場合、正常にホーム画面が表示されることを確認します。
*   **ログイン/ログアウト**: 登録したアカウントでログイン/ログアウトし、画面遷移が正しく行われることを確認します。
*   **JWT有効期限切れ時の自動ログアウト**: しばらくアプリを放置するなどしてセッションが期限切れになった際、自動的にログアウトされログイン画面に戻ることを確認します。
*   **レビュー投稿**: ホーム画面の「+」ボタンから、商品名、URL、画像、カテゴリ、サブカテゴリ、レビュー、評価を入力して投稿します。
    *   **カテゴリ選択**: `ChoiceChip` が表示され、視覚的にカテゴリを選択できることを確認します。未選択時にはバリデーションエラーが表示されることを確認します。
    *   **サブカテゴリ入力**: サブカテゴリの入力時に、過去に入力されたサブカテゴリの候補が表示されることを確認します。
    *   **画像圧縮**: アップロード前に画像が圧縮され、アップロード速度やデータサイズが最適化されていることを確認します。
    *   投稿後、ホーム画面に新しいレビューが表示されることを確認します。
*   **ホーム画面の表示**: 投稿したレビュー（商品情報と最新のレビュー1件、カテゴリとサブカテゴリを含む）が、リスト形式で表示されることを確認します。
    *   **ローディング時のShimmer効果**: データ読み込み中にShimmer効果が表示されることを確認します。
    *   **画像キャッシュとプレースホルダー/エラー表示**: 画像がスムーズに表示され、読み込み中にはプレースホルダー（Shimmer効果）が、エラー時にはエラーアイコンが表示されることを確認します。
*   **カテゴリ絞り込み**: AppBarのドロップダウンからカテゴリを選択し、レビューが正しく絞り込まれることを確認します。
    *   **「すべて」フィルター**: 「すべて」を選択した際に、すべてのカテゴリのレビューが表示されることを確認します。
*   **軽量検索機能**:
    *   検索バーに商品名の一部を入力すると、リアルタイムで（デバウンス処理後に）レビューがフィルタリングされることを確認します。
    *   検索バーをクリアすると、フィルターがリセットされることを確認します。
    *   カテゴリフィルターと検索機能が連携して動作することを確認します。
*   **レスポンシブデザイン**:
    *   スマートフォンなどの狭い画面ではレビューが縦一列に表示される `ListView` レイアウトであることを確認します。
    *   タブレットやWebなどの広い画面ではレビューが複数列に表示される `GridView` レイアウトであることを確認します。
*   **レビューの長押し編集**: 自身が投稿したレビューを長押しすると、編集画面に遷移し、内容を更新できることを確認します。
    *   **画像クリア**: 編集画面で画像をクリアできることを確認します。
    *   **他者のレビュー編集**: 他者が投稿したレビューを長押しして編集しようとした場合、**適切なエラーダイアログ**が表示されることを確認します。
*   **レビューのタップ詳細表示**: レビューをタップすると、詳細画面に遷移し、すべてのレビューが表示されることを確認します。
*   **既存商品へのレビュー追加**: 詳細画面の「+」ボタンから、新しいレビューを追加し、詳細画面に反映されることを確認します。
*   **エラーハンドリング**: ログイン/登録失敗時、画像選択失敗時、レビュー投稿・更新失敗時などに、**統一されたエラーダイアログ**が表示されることを確認します。

## 今後の拡張

*   GitHub Pagesを用いたWeb版への対応
*   カテゴリ機能の強化（ネストされたサブカテゴリなど）
*   ユーザー検索・フォロー機能
*   レビューへのコメント機能
*   プッシュ通知の実装

---
This `README.md` should be placed in the root of your `favlog_app` directory.