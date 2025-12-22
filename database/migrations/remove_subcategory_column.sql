-- 古いsubcategoryカラムを削除するマイグレーション
-- このスクリプトをSupabase SQLエディタで実行してください

-- subcategory_tagsに統一するため、古いsubcategoryカラムを削除
ALTER TABLE products DROP COLUMN IF EXISTS subcategory;

-- 確認用クエリ
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'products';
