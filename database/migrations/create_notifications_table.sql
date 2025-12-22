-- 通知テーブルを作成するマイグレーション
-- このスクリプトをSupabase SQLエディタで実行してください

-- notificationsテーブルの作成
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

-- ユーザーは自分の通知のみ閲覧可能
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- ユーザーは自分の通知を更新可能（既読にする）
CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- ユーザーは自分の通知を削除可能
CREATE POLICY "Users can delete their own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- 全ユーザーが通知を作成可能（他のユーザーへの通知を送信するため）
CREATE POLICY "All authenticated users can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 確認用クエリ
-- SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;
