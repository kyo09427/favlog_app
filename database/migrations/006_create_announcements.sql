-- お知らせ機能のマイグレーション

-- announcements テーブル作成
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT DEFAULT 'news',
  priority INTEGER DEFAULT 2 CHECK (priority IN (1, 2, 3)),
  published_at TIMESTAMPTZ DEFAULT now()
);

-- announcement_reads テーブル作成
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  announcement_id UUID REFERENCES announcements(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, announcement_id)
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_announcements_published_at ON announcements(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_user_id ON announcement_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement_id ON announcement_reads(announcement_id);

-- RLSポリシー設定（announcements）
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "認証済みユーザーは全お知らせを閲覧可能" ON announcements
  FOR SELECT
  TO authenticated
  USING (true);

-- RLSポリシー設定（announcement_reads）
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分の既読情報を閲覧可能" ON announcement_reads
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分の既読情報を追加可能" ON announcement_reads
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ユーザーは自分の既読情報を削除可能" ON announcement_reads
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- プロフィールテーブルに管理者フラグを追加
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 管理者のみお知らせを作成可能
CREATE POLICY "管理者のみお知らせを作成可能" ON announcements
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.is_admin = TRUE
    )
  );

-- 管理者のみお知らせを更新可能
CREATE POLICY "管理者のみお知らせを更新可能" ON announcements
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.is_admin = TRUE
    )
  );

-- 管理者のみお知らせを削除可能
CREATE POLICY "管理者のみお知らせを削除可能" ON announcements
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.is_admin = TRUE
    )
  );
