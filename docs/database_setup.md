# データベースセットアップ

このドキュメントでは、FavLogアプリケーションで使用するSupabaseデータベースのセットアップ手順を詳しく説明します。

## 目次

- [Supabaseプロジェクトの作成](#supabaseプロジェクトの作成)
- [APIキーの設定](#apiキーの設定)
- [データベーススキーマの作成](#データベーススキーマの作成)
- [Storage（ストレージ）の設定](#storageストレージの設定)
- [認証設定](#認証設定)

## Supabaseプロジェクトの作成

1. [Supabase公式サイト](https://supabase.com/) にアクセスし、アカウントを作成またはログインします。
2. 新しいプロジェクトを作成します。プロジェクトの地域は、ユーザーの所在地に近い場所を選択してください。

## APIキーの設定

Supabaseプロジェクトの「Settings」>「API」セクションから、以下の情報を取得し、プロジェクトルートにある `.env` ファイルに設定します。

- **Project URL**: `https://YOUR_PROJECT_REF.supabase.co`
- **Anon (public) key**: `eyJ...`

`.env` ファイルの例:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

**重要**: `.env` ファイルはGitの管理下に置かないよう、`.gitignore` に追加してください。

## データベーススキーマの作成

Supabaseダッシュボードの「SQL Editor」で以下のSQLを実行し、必要なテーブルとRow Level Security (RLS) ポリシーを設定します。

### `products` テーブル

商品情報を格納するテーブルです。

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  url TEXT,
  name TEXT NOT NULL,
  category TEXT,
  subcategory TEXT,
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

### `profiles` テーブル

ユーザープロフィール情報を格納するテーブルです。

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

### `reviews` テーブル

レビュー情報を格納するテーブルです。

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  review_text TEXT NOT NULL,
  rating REAL NOT NULL CHECK (rating >= 1 AND rating <= 5)
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

### `likes` テーブル

レビューへのいいね機能を実現するテーブルです。

```sql
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, review_id)
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

### `comments` テーブル

レビューへのコメント機能を実現するテーブルです。

```sql
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

### `notifications` テーブル

アプリ内通知機能を実現するテーブルです。新規レビュー、いいね、コメントの各イベントで通知が生成されます。

```sql
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('new_review', 'like', 'comment')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE
);

-- インデックスの作成（クエリパフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- RLSポリシーの設定
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "All authenticated users can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
```

### `user_settings` テーブル

ユーザーごとの通知設定を管理するテーブルです。

```sql
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  enable_new_review_notifications BOOLEAN DEFAULT TRUE,
  enable_like_notifications BOOLEAN DEFAULT TRUE,
  enable_comment_notifications BOOLEAN DEFAULT TRUE
);

-- RLSポリシーの設定
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own settings"
  ON user_settings FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own settings"
  ON user_settings FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own settings"
  ON user_settings FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 更新日時を自動更新するトリガー
CREATE OR REPLACE FUNCTION update_user_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_settings_updated_at
  BEFORE UPDATE ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_settings_updated_at();
```

### RPC関数

検索機能やパフォーマンス最適化のため、以下のデータベース関数を作成します。

#### いいね数・コメント数の取得

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

#### 最新レビューの取得

```sql
CREATE OR REPLACE FUNCTION get_latest_reviews_by_product_ids(
  p_product_ids UUID[],
  p_current_user_id UUID DEFAULT NULL
)
RETURNS SETOF reviews AS $$
BEGIN
  RETURN QUERY
  WITH ranked_reviews AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY created_at DESC) as rn
    FROM reviews
    WHERE product_id = ANY(p_product_ids)
  )
  SELECT *
  FROM ranked_reviews
  WHERE rn = 1
    AND (
      visibility = 'public'
      OR (
        p_current_user_id IS NOT NULL AND (
          (visibility = 'friends' AND user_id = p_current_user_id)
          OR
          (visibility = 'private' AND user_id = p_current_user_id)
        )
      )
    );
END;
$$ LANGUAGE plpgsql;
```

#### 平均評価の取得

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

## Storage（ストレージ）の設定

Supabaseダッシュボードの「Storage」セクションで、画像アップロード用のバケットを作成し、RLSポリシーを設定します。

### `product_images` バケット

商品画像を保存するバケットです。

1. 「**New bucket**」をクリックし、バケット名を `product_images` とします。
2. 「**Public bucket**」のチェックボックスをオンにします。
3. 以下のSQLを「SQL Editor」で実行し、RLSポリシーを設定します。

```sql
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

### `avatars` バケット

ユーザーのアバター画像を保存するバケットです。

1. 「**New bucket**」をクリックし、バケット名を `avatars` とします。
2. 「**Public bucket**」のチェックボックスをオンにします。
3. 以下のSQLを「SQL Editor」で実行し、RLSポリシーを設定します。

```sql
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

## 認証設定

Supabaseプロジェクトの「Authentication」>「Settings」セクションで、「**Redirect URLs**」に以下のURLを追加します。これはメール認証後のリダイレクト先として必要です。

- `io.supabase.flutterquickstart://login`

---

データベースのセットアップが完了したら、[メインREADME](../README.md)に戻ってアプリケーションの実行を進めてください。
