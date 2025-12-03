# 人気キーワード機能 実装企画書

## 1. 機能概要

### 1.1. 目的
検索画面において、静的なダミーデータで表示されている「人気のキーワード」を、アプリ内の実際のユーザーアクティビティに基づいた動的なリストに置き換える。これにより、ユーザーは話題のトピックや関心の高いアイテムを簡単に見つけられるようになる。

### 1.2. 仕様
- **アルゴリズム**: レビューの「平均評価」「レビュー数」「最終投稿日」を基にした「時間減衰付き重み付けスコア」方式を採用する。
- **集計単位**: 商品の `subcategory`（サブカテゴリ）をキーワードとして扱う。
- **表示内容**: 算出されたスコアが最も高い上位5つのサブカテゴリを「人気のキーワード」として表示する。
- **データ更新**: ユーザーが検索画面を開くたびに、最新のランキングが非同期で読み込まれる。

---

## 2. スコアリングアルゴリズム詳細

### 2.1. 計算式の全体像
各サブカテゴリの最終的なスコアは、以下の式で算出される。

**`final_score = base_score * time_factor`**

- **`base_score`**: そのサブカテゴリ自体の人気度を示す基本スコア。
- **`time_factor`**: 時間の経過とともにスコアの影響を減衰させるための係数。

### 2.2. ベーススコア (`base_score`)
レビューの質と量を評価するためのスコア。

**`base_score = (avg_rating * w_rating) + (review_count * w_review_count)`**

- `avg_rating`: サブカテゴリに属する全レビューの平均評価点。
- `review_count`: サブカテゴリに属する全レビューの総数。
- `w_rating` (重み): 評価の重要度を調整する係数。**初期値: `10.0`**
- `w_review_count` (重み): レビュー数の重要度を調整する係数。**初期値: `1.0`**

### 2.3. 時間減衰係数 (`time_factor`)
新しいトレンドを重視し、古い情報のスコアを徐々に下げるための係数。

**`time_factor = 1.0 / (1.0 + days_since_last_review / decay_rate)`**

- `days_since_last_review`: そのサブカテゴリ内で最も新しいレビューが投稿されてからの経過日数。
- `decay_rate` (減衰率): スコアが陳腐化する速さを制御する係数。**初期値: `30.0`** (30日経過すると時間係数が約0.5になり、スコアの影響が半減するイメージ)。

---

## 3. 実装計画

### ステップ1: バックエンド実装 (Supabase RPC関数)

`products`テーブルと`reviews`テーブルからデータを集計し、スコアリングを行ってキーワードリストを返すRPC関数をSupabase上に作成する。

- **ファイル**: Supabase管理画面の `SQL Editor` > `New query`
- **関数名**: `get_popular_keywords`
- **言語**: `plpgsql`
- **コード**: 以下のSQLを実行して関数を作成する。

```sql
CREATE OR REPLACE FUNCTION get_popular_keywords(limit_count INT DEFAULT 5)
RETURNS TABLE (
  keyword TEXT,
  score NUMERIC
) AS $$
DECLARE
  -- パラメータ設定 --
  _w_rating NUMERIC := 10.0;
  _w_review_count NUMERIC := 1.0;
  _decay_rate NUMERIC := 30.0;
BEGIN
  RETURN QUERY
  WITH subcategory_stats AS (
    SELECT
      p.subcategory,
      COUNT(r.id) AS review_count,
      AVG(r.rating) AS avg_rating,
      MAX(r.created_at) AS last_review_date
    FROM
      products p
    JOIN
      reviews r ON p.id = r.product_id
    WHERE
      p.subcategory IS NOT NULL AND p.subcategory != ''
    GROUP BY
      p.subcategory
  )
  SELECT
    ss.subcategory AS keyword,
    -- final_score の計算
    (
      (ss.avg_rating * _w_rating) + (ss.review_count * _w_review_count)
    )
    *
    (
      1.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - ss.last_review_date)) / 86400) / _decay_rate)
    ) AS score
  FROM
    subcategory_stats ss
  ORDER BY
    score DESC
  LIMIT
    limit_count;
END;
$$ LANGUAGE plpgsql;
```

### ステップ2: データ層実装 (Flutter)

#### 2.1. リポジトリインターフェースの更新
カテゴリ関連のデータ取得ロジックを定義する。

- **ファイル**: `lib/domain/repositories/category_repository.dart`
- **内容**: 既存の `CategoryRepository` クラスに以下のメソッドを追加する。

```dart
abstract class CategoryRepository {
  Future<List<String>> getCategories();
  Future<List<String>> getPopularKeywords(); // この行を追加
}
```

#### 2.2. Supabaseリポジトリの実装
RPC関数を呼び出す具体的な実装を行う。

- **ファイル**: `lib/data/repositories/supabase_category_repository.dart` (※新規作成)
- **内容**:

```dart
import 'package:favlog_app/domain/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;

  SupabaseCategoryRepository(this._client);

  @override
  Future<List<String>> getCategories() async {
    // 既存のカテゴリ取得ロジックがあればここに実装
    // 今回のタスクでは実装不要
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getPopularKeywords() async {
    try {
      final List<dynamic> result = await _client.rpc(
        'get_popular_keywords',
        params: {'limit_count': 5},
      );
      
      if (result.isEmpty) {
        return [];
      }
      
      final keywords = result.map((e) => e['keyword'] as String).toList();
      return keywords;

    } catch (e) {
      // TODO: より詳細なエラーハンドリングを実装
      print('Failed to fetch popular keywords: $e');
      rethrow;
    }
  }
}
```

#### 2.3. Providerの作成・更新
DIコンテナに新しいリポジトリと、人気キーワードを取得するための `FutureProvider` を登録する。

- **ファイル**: `lib/presentation/providers/category_providers.dart`
- **内容**:

```dart
import 'package:favlog_app/data/repositories/supabase_category_repository.dart';
import 'package:favlog_app/domain/repositories/category_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'category_providers.g.dart'; // Riverpod Generator を利用する場合

// SupabaseCategoryRepository を提供する Provider
@riverpod
CategoryRepository supabaseCategoryRepository(SupabaseCategoryRepositoryRef ref) {
  return SupabaseCategoryRepository(Supabase.instance.client);
}

// 人気キーワードのリストを提供する FutureProvider
@riverpod
Future<List<String>> popularKeywords(PopularKeywordsRef ref) {
  final categoryRepository = ref.watch(supabaseCategoryRepositoryProvider);
  return categoryRepository.getPopularKeywords();
}

// --- 既存の AssetCategoryRepository 関連の Provider はそのまま残す ---
```
**注意**: 上記は `riverpod_generator` を利用した記法です。手動で書く場合は `Provider` と `FutureProvider` を定義してください。また、`asset_category_repository.dart` を使用している既存の `categoryRepositoryProvider` は、`assetCategoryRepositoryProvider` のように改名し、新しい `supabaseCategoryRepositoryProvider` と共存させる必要があります。

### ステップ3: UI層実装 (Flutter)

`search_screen.dart` を修正し、静的なキーワードリストを `popularKeywordsProvider` から取得した動的なリストに置き換える。

- **ファイル**: `lib/presentation/screens/search_screen.dart`
- **修正方針**:
    1. `StatefulWidget` を `ConsumerWidget` に変更する。
    2. ハードコードされた `_popularKeywords` リストを削除する。
    3. `build` メソッド内で `ref.watch(popularKeywordsProvider)` を呼び出す。
    4. `AsyncValue` の状態（`data`, `loading`, `error`）に応じてUIを構築する。

- **実装イメージ**:

```dart
// class SearchScreen extends StatefulWidget -> class SearchScreen extends ConsumerWidget
class SearchScreen extends ConsumerWidget { 
  const SearchScreen({super.key});

  @override
  // Widget build(BuildContext context) -> Widget build(BuildContext context, WidgetRef ref)
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (既存のコード)

    // 人気のキーワード部分の修正
    // final List<String> _popularKeywords = [...] // この行を削除

    return Scaffold(
      // ... (既存のコード)
      body: Column(
        children: [
          // ... (検索バーなど)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '人気のキーワード',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // popularKeywordsProvider を watch
                ref.watch(popularKeywordsProvider).when(
                  data: (keywords) {
                    if (keywords.isEmpty) {
                      return const Center(child: Text('人気のキーワードはありません。'));
                    }
                    return Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: keywords.map((keyword) {
                        return ActionChip(
                          label: Text(keyword),
                          onPressed: () {
                            // キーワードをタップしたときの検索処理
                            // (既存のロジックを流用)
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('キーワードの取得に失敗しました: $err')),
                ),
              ],
            ),
          ),
          // ...
        ],
      ),
    );
  }
}
```

---

## 4. テスト計画

### 4.1. バックエンド
1. SupabaseのSQL Editorで `SELECT * FROM get_popular_keywords(5);` を実行する。
2. 返却されるキーワードとスコアが、手計算した期待値とおおむね一致することを確認する。
3. `products` や `reviews` のデータを変更し、再度実行してランキングが変動することを確認する。

### 4.2. フロントエンド
1. 検索画面を開いた際に、ローディングインジケータが表示されることを確認する。
2. ローディング後、RPC関数から返されたキーワードがチップとして表示されることを確認する。
3. キーワードのチップをタップすると、そのキーワードで検索が実行されることを確認する。
4. RPC関数が意図的にエラーを返すように変更（またはネットワークをオフに）し、エラーメッセージが画面に表示されることを確認する。
5. キーワードが1件も返らない場合に「人気のキーワードはありません。」と表示されることを確認する。

---

## 5. 将来的な拡張

本機能の将来的な拡張を検討する際には、このセクションのアイデアに加えて、プロジェクト全体の指針が記述されている `FAVLOG_DEVELOPMENT_ROADMAP.md` も必ず参照してください。

- **いいね・コメント機能の追加**: 将来的にいいねやコメント機能が実装された場合、`get_popular_keywords` RPC関数内のスコア計算式にそれらの要素（`likes * w_likes`, `comments * w_comments`）を追加する。
- **パラメータの動的変更**: アプリの成長に合わせて最適な重み付けが変わる可能性があるため、管理画面などから`w_rating`や`decay_rate`といったパラメータを動的に変更できる仕組みを検討する。
