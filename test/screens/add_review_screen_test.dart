import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ProviderScopeのためにインポート
import 'package:favlog_app/presentation/screens/add_review_screen.dart';

void main() {
  testWidgets('AddReviewScreen renders correctly', (WidgetTester tester) async {
    // Note: This test now uses dummy providers since the controller depends on them.
    // A more robust test would use Mockito to mock these dependencies.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AddReviewScreen()),
      ),
    );

    // Header title
    expect(find.text('レビュー投稿'), findsOneWidget);
    
    // Form field labels
    expect(find.text('商品・サービス名'), findsOneWidget);
    expect(find.text('商品URL (任意)'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.text('サブカテゴリ (任意)'), findsOneWidget);
    expect(find.text('評価'), findsOneWidget);
    expect(find.text('写真を追加'), findsNWidgets(2));
    expect(find.text('レビュー本文'), findsOneWidget);
    expect(find.text('公開範囲'), findsOneWidget);

    // Submit button
    expect(find.text('レビューを投稿する'), findsOneWidget);
  });

  // More detailed tests would involve mocking Supabase interactions,
  // which is beyond the scope of this basic rendering test.
}