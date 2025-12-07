-- Productsテーブルのsubcategoryをsubcategory_tagsに変更するマイグレーション
-- このスクリプトをSupabase SQLエディタで実行してください

-- 1. subcategory_tagsカラムを追加（複数のサブカテゴリタグを保存）
ALTER TABLE products
ADD COLUMN IF NOT EXISTS subcategory_tags TEXT[] DEFAULT '{}';

-- 2. 既存のsubcategoryデータをsubcategory_tagsに移行
UPDATE products
SET subcategory_tags = ARRAY[subcategory]
WHERE subcategory IS NOT NULL AND subcategory != '';

-- 3. 古いsubcategoryカラムは互換性のため残す
-- 必要に応じて削除: ALTER TABLE products DROP COLUMN subcategory;

-- 4. インデックスを作成（クエリのパフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_products_subcategory_tags ON products USING GIN (subcategory_tags);

-- 確認用クエリ
-- SELECT id, name, category, subcategory, subcategory_tags
-- FROM products
-- LIMIT 10;
