import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ProviderScopeのためにインポート
import 'package:favlog_app/presentation/screens/add_review_screen.dart';

void main() {
  testWidgets('AddReviewScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope( // ProviderScopeでラップ
        child: MaterialApp(home: AddReviewScreen()),
      ),
    );

    expect(find.text('レビューを追加'), findsOneWidget);
    expect(find.text('商品名'), findsOneWidget);
    expect(find.text('商品URL (オプション)'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget); // テキストを修正 (オプションが削除されたため)
    expect(find.text('画像をタップして選択 (オプション)'), findsOneWidget);
    expect(find.text('レビュー'), findsOneWidget);
    expect(find.text('レビューを投稿'), findsOneWidget);
  });

  // More detailed tests would involve mocking Supabase interactions,
  // which is beyond the scope of this basic rendering test.
}