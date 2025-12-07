# レビュー投稿機能の更新

## 概要

レビュー投稿機能を2段階のフローに変更し、複数画像対応、サブカテゴリタグ、公開範囲設定を追加しました。

## 新しいフロー

### 1. 商品選択画面 (`ProductSelectionScreen`)

- 検索機能で商品を探せる
- 最近レビューした商品が表示される
- 商品を選択してレビュー投稿画面へ遷移

### 2. レビュー投稿画面 (`AddReviewScreen`)

- 選択された商品情報を表示
- 星評価（0.5刻み、1.0〜5.0）
- 複数画像アップロード（最大3枚）
- レビュー本文
- サブカテゴリタグ（複数設定可能）
- 公開範囲設定（全体公開、親しい友達、非公開）

## データモデルの変更

### `Review`モデル

```dart
class Review {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String productId;
  final String reviewText;
  final double rating;
  final List<String> imageUrls;        // 新規: 複数画像のURL
  final List<String> subcategoryTags;  // 新規: サブカテゴリのタグ
  final String visibility;             // 新規: 公開範囲
}
```

### Supabaseデータベースの更新

`database/migrations/add_review_fields.sql`を実行してください：

```sql
-- 1. image_urlsカラムを追加
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- 2. subcategory_tagsカラムを追加
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS subcategory_tags TEXT[] DEFAULT '{}';

-- 3. visibilityカラムを追加
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'public';
```

## 新規ファイル

1. **`lib/presentation/screens/product_selection_screen.dart`**
   - 商品選択画面
   - 検索機能、最近レビューした商品リスト

2. **`lib/presentation/providers/add_review_controller.dart`** (大幅更新)
   - 複数画像対応
   - サブカテゴリタグ管理
   - 公開範囲設定

3. **`lib/presentation/screens/add_review_screen.dart`** (完全書き直し)
   - 新しいUIデザイン
   - 複数画像グリッド表示
   - タグ入力・管理
   - 公開範囲ダイアログ

## 更新されたファイル

1. **`lib/domain/models/review.dart`**
   - `imageUrls`, `subcategoryTags`, `visibility`フィールドを追加

2. **`lib/core/router/app_router.dart`**
   - `/product-selection`ルートを追加
   - `/add-review`ルートを更新して商品情報を受け取れるように

3. **`lib/presentation/screens/home_screen.dart`**
   - FloatingActionButtonを商品選択画面へのリンクに変更

## 使い方

### レビューを投稿する流れ

1. ホーム画面の右下「+」ボタンをタップ
2. **商品選択画面**が開く
   - 検索バーで商品を検索
   - または「最近レビューしたもの」から選択
   - 商品をタップして選択
3. **レビュー投稿画面**が開く
   - 星をタップして評価を設定
   - 「追加」ボタンで画像を追加（最大3枚）
   - レビュー本文を入力
   - サブカテゴリタグを追加（任意）
   - 公開範囲を設定
   - 「レビューを投稿する」ボタンをタップ

## 今後の実装予定

- ✅ 商品選択画面
- ✅ レビュー投稿画面（複数画像、タグ、公開範囲）
- ⏳ 新しい商品を追加する機能
- ⏳ 公開範囲に基づいたレビュー表示フィルタリング
- ⏳ タグによる検索・フィルタリング

## 注意事項

### データベースマイグレーション

必ずSupabaseの管理画面で`add_review_fields.sql`を実行してください。実行しないと、新しいレビューの投稿でエラーが発生します。

### 既存データの互換性

既存のレビューデータは新しいフィールドにデフォルト値が設定されるため、互換性が保たれます：

- `image_urls`: 空配列 `[]`
- `subcategory_tags`: 空配列 `[]`
- `visibility`: `'public'`

### テスト

現在のテストは古い実装に基づいているため、更新が必要です。
