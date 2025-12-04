# FavLog (Favorite Log) アプリケーション README

## 概要

FavLogは、クローズドなコミュニティ（友人、家族、同僚など）内で商品やサービスのレビューを共有するためのAndroidアプリケーションです。
検索アルゴリズムではなく、信頼できる関係に基づいた選択を支援します。

### 主要機能

*   **アカウント管理**: ユーザー登録、ログイン、ログアウト機能。メール認証フローの改善（未確認ユーザーへの警告表示、リセンドメール機能）。**JWT有効期限切れ時の自動ログアウトと再認証誘導**。
*   **プロフィール管理**: ユーザー名とアバター画像の設定・更新。既存アバターの自動削除と手動更新機能。
*   **レビュー投稿**: 商品名、URL、画像、カテゴリ（ChoiceChipによる視覚的選択）、サブカテゴリ（自由入力、**オートコンプリート候補表示**）、レビューテキスト、評価（0.5単位の星）を含むレビューを投稿。**画像アップロード時にWebP形式への変換と圧縮を自動実行**。
*   **レビュー表示**: レビュアーのプロフィールと共に、ホーム画面には**商品の平均評価**と最新レビュー1件が表示されます。詳細画面ではその商品のすべてのレビューが一覧表示されます。**ローディング状態の改善（Shimmer効果）**、**UI/UXの改善（テキストの省略表示）**。**無限スクロールによる動的なデータ読み込み**。**再開時の自動データ更新**。
*   **レビュー編集**: レビュー詳細画面から、自身のレビューを編集可能。評価、レビュー本文を更新できます。
*   **レビュー削除**: レビュー詳細画面から、自身のレビューを削除可能。
*   **詳細画面**: 商品の全情報（平均評価、レビュー数を含む）と、それに対するすべてのレビューを一覧表示。レビューのソートUI、**プルツーリフレッシュによる手動更新**に対応。
*   **既存商品へのレビュー追加**: 詳細画面から、同一商品に対して別のユーザーがレビューを追加可能。
*   **強化されたナビゲーション**: アプリ全体のナビゲーションフローを洗練し、`CommonBottomNavBar`による一貫したボトムナビゲーションと、各画面（ホーム、検索、プロフィール）への制御されたスタック管理を実装。
*   **ソーシャル機能**:
    *   **いいね機能**: レビューに対していいねを付けることができます。いいね数がリアルタイムで表示され、ハートアイコンで視覚的にフィードバックされます。
    *   **コメント機能**: レビューに対してコメントを投稿できます。コメント一覧画面では、ユーザーのプロフィール画像と名前が表示され、自分のコメントは削除可能です。
    *   **レビューのソート**: レビュー詳細画面で「すべて」「新しい順」「高評価順」のソート機能を利用できます。

*   **カテゴリフィルタリング**: ホーム画面でカテゴリを選択してレビューを絞り込み表示（**「すべて」のフィルタリングロジック改善**）。
*   **検索機能**: 専用の検索画面で商品、サービス、タグ、ユーザー名を横断した検索が可能。**検索画面のUI/UX改善**（0.5単位の星評価、Riverpodによる状態管理の堅牢化、**エラー時および結果なし時の表示改善**）。
*   **画像表示の最適化**: **画像キャッシュ（CachedNetworkImage）**、読み込み中の**プレースホルダー**、エラー時の**画像表示**に加え、**画像の縦横比を維持して表示**することで、不自然な引き伸ばしや切り取られ方を防ぎます。
*   **レスポンシブデザイン**: モバイル・タブレット・Webなど、デバイスの画面幅に応じた最適なレイアウトを提供。**特にホーム画面では、画面幅に応じてレビューの一覧表示が `ListView` と `GridView` で切り替わる。**
*   **統一されたエラーハンドリング**: ネットワークエラー、認証エラーなど、エラーの種類に応じた適切なメッセージを統一的なダイアログで表示。

## 技術スタック

*   **フロントエンド**: Flutter (Dart), **Riverpod** (状態管理), **cached_network_image** (画像キャッシュ), **shimmer** (ローディングエフェクト), **intl** (国際化サポート)
*   **バックエンド**: Supabase (PostgreSQL Database, Supabase Auth, Supabase Storage)
*   **ユーティリティ**: **flutter_dotenv** (環境変数管理), **image** (画像処理), **flutter_image_compress** (WebP画像圧縮)
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

#### `profiles` テーブル

```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  username TEXT UNIQUE,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile."
  ON profiles FOR UPDATE USING (auth.uid() = id);
```

#### `reviews` テーブル

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  review_text TEXT NOT NULL,
  rating REAL NOT NULL CHECK (rating >= 1 AND rating <= 5) -- INTEGERからREALに変更し、0.5単位の評価に対応
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
#### `likes` テーブル (いいね機能)
```sql
-- いいねテーブル
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, review_id) -- 1ユーザーは1レビューに1いいねのみ
);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "認証済みユーザーは全てのいいねを閲覧可能" ON likes
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "ユーザーは自分のいいねを追加可能" ON likes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分のいいねを削除可能" ON likes
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

#### `comments` テーブル (コメント機能)
```sql
-- コメントテーブル
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE NOT NULL,
  comment_text TEXT NOT NULL CHECK (length(comment_text) > 0)
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "認証済みユーザーは全てのコメントを閲覧可能" ON comments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "ユーザーは自分のコメントを追加可能" ON comments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分のコメントを更新可能" ON comments
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分のコメントを削除可能" ON comments
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

#### RPC関数 (いいね数・コメント数の効率的な取得)

検索機能やレビュー詳細画面のパフォーマンスを最適化するため、以下のSQLを「SQL Editor」で実行し、いいね数とコメント数を一括で取得するためのデータベース関数を作成します。
```sql
-- いいね数を効率的に取得するためのRPC関数
CREATE OR REPLACE FUNCTION get_like_counts(review_ids UUID[])
RETURNS TABLE(review_id UUID, like_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.review_id,
    COUNT(l.id)::BIGINT AS like_count
  FROM
    likes l
  WHERE
    l.review_id = ANY(review_ids)
  GROUP BY
    l.review_id;
END;
$$ LANGUAGE plpgsql;

-- コメント数を効率的に取得するためのRPC関数
CREATE OR REPLACE FUNCTION get_comment_counts(review_ids UUID[])
RETURNS TABLE(review_id UUID, comment_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.review_id,
    COUNT(c.id)::BIGINT AS comment_count
  FROM
    comments c
  WHERE
    c.review_id = ANY(review_ids)
  GROUP BY
    c.review_id;
END;
$$ LANGUAGE plpgsql;
```

#### RPC (Remote Procedure Call) 関数の作成

検索機能のパフォーマンスを最適化するため、以下のSQLを「SQL Editor」で実行し、関連するレビューを一括で取得するためのデータベース関数を作成します。

```sql
CREATE OR REPLACE FUNCTION get_latest_reviews_by_product_ids(p_product_ids UUID[])
RETURNS SETOF reviews AS $$
BEGIN
  RETURN QUERY
  SELECT r.*
  FROM reviews r
  WHERE r.id IN (
    SELECT id
    FROM (
      SELECT id, ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY created_at DESC) as rn
      FROM reviews
      WHERE product_id = ANY(p_product_ids)
    ) t
    WHERE t.rn = 1
  );
END;
$$ LANGUAGE plpgsql;
```

ホーム画面での平均評価表示を効率化するため、以下の関数も追加します。

```sql
CREATE OR REPLACE FUNCTION get_product_rating_stats(p_product_ids UUID[])
RETURNS TABLE(product_id UUID, average_rating DOUBLE PRECISION, review_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.product_id,
    AVG(r.rating)::DOUBLE PRECISION AS average_rating,
    COUNT(r.id)::BIGINT AS review_count
  FROM
    reviews r
  WHERE
    r.product_id = ANY(p_product_ids)
  GROUP BY
    r.product_id;
END;
$$ LANGUAGE plpgsql;
```

### 4. Storage (ストレージ) の設定

Supabaseダッシュボードの「Storage」セクションで、画像アップロード用のバケットを作成し、RLSポリシーを設定します。

1.  「**New bucket**」をクリックし、バケット名を `product_images` とします。
2.  「**Public bucket**」のチェックボックスをオンにします。
3.  以下のSQLを「SQL Editor」で実行し、`product_images` バケットのRLSポリシーを設定します。

#### `avatars` バケット (新規追加)

`avatars`という名前で新しいバケットを作成し、RLSポリシーを設定してください。

1.  「**New bucket**」をクリックし、バケット名を `avatars` とします。
2.  「**Public bucket**」のチェックボックスをオンにします。
3.  以下のSQLを「SQL Editor」で実行し、`avatars` バケットのRLSポリシーを設定します。

```sql
-- 'avatars'バケットのストレージポリシーを設定する

-- アバター画像を誰でも閲覧できるようにするポリシー
CREATE POLICY "Avatar images are publicly accessible."
  ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- 認証済みユーザーが自身のアバターをアップロードできるようにするポリシー
CREATE POLICY "Authenticated users can upload an avatar."
  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);

-- 認証済みユーザーが自身のアバターを更新できるようにするポリシー
CREATE POLICY "Authenticated users can update their own avatar."
  ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid() = owner);

-- 認証済みユーザーが自身のアバターを削除できるようにするポリシー
CREATE POLICY "Authenticated users can delete their own avatar."
  ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid() = owner);
```

#### `product_images` バケット (既存)

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
*   **いいね機能**: レビューのハートアイコンをタップして、いいね/いいね解除ができることを確認します。いいね数が正しく表示されることを確認します。
*   **コメント機能**: 
    *   レビューのコメントアイコンをタップして、コメント画面に遷移することを確認します。
    *   コメントを投稿し、リストに反映されることを確認します。
    *   自分のコメントを削除できることを確認します。
*   **ソート機能**: レビュー詳細画面のタブ（すべて、新しい順、高評価順）をタップして、レビューが正しくソートされることを確認します。
*   **カテゴリ絞り込み**: AppBarのドロップダウンからカテゴリを選択し、レビューが正しく絞り込まれることを確認します。
    *   **「すべて」フィルター**: 「すべて」を選択した際に、すべてのカテゴリのレビューが表示されることを確認します。
*   **軽量検索機能**:
    *   検索バーに商品名の一部を入力すると、リアルタイムで（デバウンス処理後に）レビューがフィルタリングされることを確認します。
    *   検索バーをクリアすると、フィルターがリセットされることを確認します。
    *   カテゴリフィルターと検索機能が連携して動作することを確認します。
*   **レスポンシブデザイン**:
    *   スマートフォンなどの狭い画面ではレビューが縦一列に表示される `ListView` レイアウトであることを確認します。
    *   タブレットやWebなどの広い画面ではレビューが複数列に表示される `GridView` レイアウトであることを確認します。
*   **レスポンシブデザイン**:
    *   スマートフォンなどの狭い画面ではレビューが縦一列に表示される `ListView` レイアウトであることを確認します。
    *   タブレットやWebなどの広い画面ではレビューが複数列に表示される `GridView` レイアウトであることを確認します。
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
