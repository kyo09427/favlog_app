-- Reviewsテーブルに新しいカラムを追加するマイグレーション
-- このスクリプトをSupabase SQLエディタで実行してください

-- 1. image_urlsカラムを追加（複数の画像URLを保存）
ALTER TABLE reviews
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- 2. subcategory_tagsカラムを追加（サブカテゴリのタグリスト）
ALTER TABLE reviews
ADD COLUMN IF NOT EXISTS subcategory_tags TEXT[] DEFAULT '{}';

-- 3. visibilityカラムを追加（公開範囲: 'public', 'friends', 'private'）
ALTER TABLE reviews
ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'public';

-- 4. visibilityカラムにチェック制約を追加
ALTER TABLE reviews
ADD CONSTRAINT reviews_visibility_check 
CHECK (visibility IN ('public', 'friends', 'private'));

-- 5. インデックスを作成（クエリのパフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_reviews_visibility ON reviews(visibility);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id_visibility ON reviews(user_id, visibility);

-- 確認用クエリ
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'reviews'
-- ORDER BY ordinal_position;
