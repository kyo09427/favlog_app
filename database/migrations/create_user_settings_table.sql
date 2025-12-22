-- ユーザー設定テーブルを作成するマイグレーション
-- このスクリプトをSupabase SQLエディタで実行してください

-- user_settingsテーブルの作成
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

-- ユーザーは自分の設定のみ閲覧可能
CREATE POLICY "Users can view their own settings"
  ON user_settings FOR SELECT
  USING (auth.uid() = id);

-- ユーザーは自分の設定を更新可能
CREATE POLICY "Users can update their own settings"
  ON user_settings FOR UPDATE
  USING (auth.uid() = id);

-- ユーザーは自分の設定を作成可能
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

-- 確認用クエリ
-- SELECT * FROM user_settings;
