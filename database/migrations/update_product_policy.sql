-- 商品編集権限を管理者にも付与するマイグレーション
-- 作成者または管理者のみが商品を編集・削除できるようにRLSポリシーを更新

-- 既存のポリシーを削除
DROP POLICY IF EXISTS "Users can update their own products" ON products;
DROP POLICY IF EXISTS "Users can delete their own products" ON products;

-- 新しいUPDATEポリシーを作成（作成者または管理者が更新可能）
CREATE POLICY "Users can update their own products or admins can update" ON products
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- 新しいDELETEポリシーを作成（作成者または管理者が削除可能）
CREATE POLICY "Users can delete their own products or admins can delete" ON products
  FOR DELETE
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );
