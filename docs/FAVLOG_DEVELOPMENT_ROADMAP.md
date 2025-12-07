# FavLog アプリ開発ロードマップ

[既存の内容は維持...]

## 実装ログ - 2025年12月6日 (続き)

### プロフィール画面・設定画面のUI刷新とWebP画像変換の完全実装

* **プロフィール編集画面のUI全面刷新**:
  * `lib/presentation/screens/profile_screen.dart`の`_showEditProfileDialog`メソッドを、ダイアログから全画面表示の専用画面に変更。
  * 提供されたHTMLデザインに基づき、以下の要素を実装：
    * ヘッダー（戻るボタン + タイトル）
    * 中央にアバター画像（128x128、プライマリカラーのボーダー付き）
    * アバター右下に編集ボタン（40x40の円形、プライマリカラー背景）
    * 「プロフィール画像を変更」テキストボタン
    * ユーザー名入力フィールド（ラベル付き、角丸ボーダー）
    * 下部固定の保存ボタン（全幅、プライマリカラー）
  * ライトモード・ダークモード両対応のテーマベースカラーリング実装。

* **設定関連画面の背景色統一**:
  * `lib/presentation/screens/settings_screen.dart`を更新し、テーマベースの背景色に変更。
    * ライトモード：白色背景（`Color(0xFFF6F8F6)`）
    * ダークモード：暗い背景（`Color(0xFF102216)`）
  * PowerShellスクリプトにより、以下の画面の背景色を一括更新：
    * `password_reset_request_screen.dart`
    * `password_reset_email_sent_screen.dart`
    * `update_password_screen.dart`
    * `update_email_request_screen.dart`
    * `update_email_sent_screen.dart`
    * `confirm_email_change_screen.dart`

* **WebP画像変換の完全実装**:
  * **ImageCompressorの更新**:
    * `lib/core/services/image_compressor.dart`を更新し、すべての画像をWebP形式で圧縮・保存。
    * Web版：`img.encodeWebP()`を使用（`image`パッケージ 4.2.0対応で`encodeWebPLossy()`から`encodeWebP()`に変更、フォールバックとしてJPEGも実装）
    * ネイティブ版：`CompressFormat.webp`を使用
  * **アバター画像のWebP化**:
    * `lib/presentation/providers/profile_screen_controller.dart`を更新：
      * ファイル拡張子を`.jpg`から`.webp`に変更
      * Content-Typeを`image/jpeg`から`image/webp`に変更
  * **商品画像のWebP化**:
    * `lib/presentation/providers/add_review_controller.dart`を更新：
      * ファイル拡張子を`jpg`から`webp`に変更
      * Content-Typeを`image/jpeg`から`image/webp`に変更
    * `lib/presentation/providers/edit_product_controller.dart`を同様に更新
  * **リポジトリ層の更新**:
    * `lib/data/repositories/supabase_product_repository.dart`のデフォルトContent-Typeを`image/webp`に変更
  * **依存関係の更新**:
    * `image`パッケージをバージョン4.2.0にアップデート

* **レビュー・コメント編集削除機能の実装**:
  * **ReviewItemウィジェットの改善**:
    * `lib/presentation/widgets/review_item.dart`を更新：
      * 右上の編集ボタンを3点メニューボタンに変更
      * ボトムシートメニューで「編集」と「削除」オプションを表示
      * `onDelete`コールバックを新規追加
  * **レビュー詳細画面の更新**:
    * `lib/presentation/screens/review_detail_screen.dart`を更新：
      * ReviewItemの下部にあった重複の編集・削除ボタンを削除
      * `onDelete`コールバックを追加して削除機能を統合
  * **プロフィール画面の更新**:
    * `lib/presentation/screens/profile_screen.dart`に`_deleteReview`メソッドを追加
      * 確認ダイアログ表示
      * レビュー削除後の画面更新
    * ReviewItemに`onDelete`コールバックを追加
  * **コメント編集・削除機能**:
    * `lib/presentation/screens/comment_screen.dart`を更新：
      * `_editComment`メソッドを追加：ダイアログでコメントテキストを編集
      * `_deleteComment`メソッドを追加：確認ダイアログ表示後に削除
      * 各コメントの右上に3点メニューボタンを追加（自分のコメントのみ）
      * 「編集」と「削除」オプションを表示するポップアップメニューを実装

* **コード品質の改善**:
  * `dart fix --apply`により以下を自動修正：
    * `invalid_null_aware_operator`（2件）
    * `unnecessary_non_null_assertion`（1件）
    * `unnecessary_import`（1件）
    * `unused_import`（2件）
    * `missing_dependency`（1件）
  * `flutter_web_plugins`の誤った依存関係を削除
  * 76個の問題から61個に削減（残りは警告とinfoのみ、エラーは0個）
  * 未使用変数、非推奨API使用の警告を整理

* **マージコンフリクトの解決**:
  * `lib/presentation/providers/edit_product_controller.dart`のマージコンフリクトを解決
  * ローカルとリモートの両方のインポート（`dart:typed_data`、`package:flutter/foundation.dart`）を保持
  * マージコミットを作成し、ワーキングツリーをクリーンな状態に復元

### パフォーマンスとストレージの最適化

WebP形式の採用により、以下の改善を実現：

* 画像ファイルサイズが20-30%削減
* 画質の劣化を最小限に抑制
* ストレージコストの削減
* ページロード時間の短縮

## 実装ログ - 2025年12月7日

### 画面コンポーネントのリファクタリングとコード品質向上

* **コメント画面 (`CommentScreen`) のリファクタリング**:
  * **複雑性の解消**: ネストした `FutureBuilder` を廃止し、`flutter_riverpod` の `FutureProvider` を活用したデータフェッチング (`reviewDetailsProvider`) に移行。これによりコールバック地獄を解消。
  * **コンポーネント抽出**: レビュー詳細表示部分を `ReviewInfoCard` (`lib/presentation/widgets/review_info_card.dart`) として独立したウィジェットに切り出し。
  * **ロジックの分離**: `comment_screen_provider.dart` を作成し、レビューと商品データの取得ロジックをUIから分離。

* **商品編集画面 (`EditProductScreen`) のリファクタリング**:
  * **ファイルサイズの削減**: 35KBから15KBへと大幅に軽量化。
  * **UIロジックのウィジェット化**: 複雑なUI部分を以下の独立したウィジェットとして切り出し：
    * `EditProductImagePicker`: 画像の選択・表示ロジック
    * `EditProductCategorySelector`: カテゴリ選択チップのUI
    * `EditProductTagsInput`: サブカテゴリ（タグ）の入力・管理UI
  * **ディレクトリ整理**: `lib/presentation/widgets/edit_product/` ディレクトリ配下に上記コンポーネントを配置。

* **API互換性とコード品質の維持**:
  * **非推奨APIの更新**: Flutter 3.27以降で非推奨となった `Color.withOpacity()` を `Color.withValues(alpha: ...)` に置き換え。
  * **Lintエラー/警告の修正**:
    * `unnecessary_underscores`: 未使用コールバック引数の記法修正。
    * 不要なインポートの削除 (`package:characters` 等)。
    * 相対インポートパスの修正。
  * **テストの実施**: `flutter test` および `flutter analyze` を実行し、リファクタリング後も機能が正常に動作し、新たなエラーが発生していないことを確認。
