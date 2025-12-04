import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: この画面の実装を行う
// 1. reviewIdに基づいてレビューと関連商品データを取得するProviderを作成する
// 2. 取得したデータを使ってReviewItemウィジェットなどを表示する
// 3. エラーハンドリングとローディング表示を実装する

class SingleReviewScreen extends ConsumerWidget {
  final String reviewId;

  const SingleReviewScreen({super.key, required this.reviewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レビュー詳細'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '個別レビュー表示画面',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text('Review ID: $reviewId'),
            const SizedBox(height: 32),
            const Text('（この画面は現在実装中です）'),
          ],
        ),
      ),
    );
  }
}
