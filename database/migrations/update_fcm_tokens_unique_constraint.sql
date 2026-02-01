-- FCMトークンテーブルのUNIQUE制約を変更するマイグレーション
-- UNIQUE(user_id, token) から UNIQUE(user_id, device_type) に変更
-- これにより、1ユーザー・1デバイスタイプにつき1トークンのみ保持される

-- ステップ1: 既存のUNIQUE制約を削除
ALTER TABLE fcm_tokens DROP CONSTRAINT IF EXISTS fcm_tokens_user_id_token_key;

-- ステップ2: device_type をNOT NULLに変更（既存データでNULLの場合はデフォルト値を設定）
UPDATE fcm_tokens SET device_type = 'android' WHERE device_type IS NULL;

-- ステップ3: 重複レコードを削除（最新のものだけを残す）
-- UNIQUE制約を追加する前に重複を削除する必要がある
DELETE FROM fcm_tokens a 
USING fcm_tokens b
WHERE a.id < b.id
  AND a.user_id = b.user_id
  AND a.device_type = b.device_type;

-- ステップ4: device_typeをNOT NULLに設定
ALTER TABLE fcm_tokens ALTER COLUMN device_type SET NOT NULL;

-- ステップ5: 新しいUNIQUE制約を追加（user_id, device_type）
ALTER TABLE fcm_tokens ADD CONSTRAINT fcm_tokens_user_id_device_type_key UNIQUE(user_id, device_type);
