import 'package:favlog_app/core/providers/common_providers.dart';
import 'package:favlog_app/data/repositories/asset_category_repository.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/data/repositories/supabase_product_repository.dart';
import 'package:favlog_app/data/repositories/supabase_review_repository.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/domain/repositories/category_repository.dart';
import 'package:favlog_app/domain/repositories/product_repository.dart';
import 'package:favlog_app/domain/repositories/review_repository.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/core/services/image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/screens/add_review_screen.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
class MockReviewRepository extends Mock implements ReviewRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockImageCompressor extends Mock implements ImageCompressor {}

void main() {
  late MockCategoryRepository mockCategoryRepository;
  late MockProductRepository mockProductRepository;
  late MockReviewRepository mockReviewRepository;
  late MockAuthRepository mockAuthRepository;
  late MockImageCompressor mockImageCompressor;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockProductRepository = MockProductRepository();
    mockReviewRepository = MockReviewRepository();
    mockAuthRepository = MockAuthRepository();
    mockImageCompressor = MockImageCompressor();
  });

  Widget createAddReviewScreen({Product? selectedProduct}) {
    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepository),
        productRepositoryProvider.overrideWithValue(mockProductRepository),
        reviewRepositoryProvider.overrideWithValue(mockReviewRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        imageCompressorProvider.overrideWithValue(mockImageCompressor),
      ],
      child: MaterialApp(home: AddReviewScreen(selectedProduct: selectedProduct)),
    );
  }

  testWidgets('AddReviewScreen renders correctly with selected product', (WidgetTester tester) async {
    // Create a test product
    final testProduct = Product(
      userId: 'test-user-id',
      name: 'テスト商品',
      category: '本',
      subcategoryTags: ['ミステリー'],
      imageUrl: 'https://example.com/image.jpg',
    );

    await tester.pumpWidget(createAddReviewScreen(selectedProduct: testProduct));
    await tester.pumpAndSettle();

    // Check if header title is displayed
    expect(find.text('レビュー投稿'), findsOneWidget);

    // Check if product name is displayed
    expect(find.text('テスト商品'), findsOneWidget);

    // Check if rating section is present
    expect(find.text('評価'), findsOneWidget);
    
    // Check if rating stars are present
    // デフォルトの評価が3.5なので、3つのfilled星、1つのhalf星、1つのborder星
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half), findsNWidgets(1));
    expect(find.byIcon(Icons.star_border), findsNWidgets(1));

    // Check if image section is present
    expect(find.text('写真を追加'), findsOneWidget);

    // Check if review text section is present
    expect(find.text('レビュー本文'), findsOneWidget);

    // Check if subcategory section is present
    expect(find.text('サブカテゴリ (任意)'), findsOneWidget);

    // Check if visibility section is present
    expect(find.text('公開範囲'), findsOneWidget);
    expect(find.text('全体に公開'), findsOneWidget);

    // Check if submit button is present
    expect(find.text('レビューを投稿する'), findsOneWidget);
  });

  testWidgets('AddReviewScreen renders when no product is selected', (WidgetTester tester) async {
    await tester.pumpWidget(createAddReviewScreen(selectedProduct: null));
    await tester.pumpAndSettle();

    // レビュー投稿画面はレンダリングされるべき
    expect(find.text('レビュー投稿'), findsOneWidget);
    
    // 商品情報が表示されないことを確認（selectedProductがnullの場合）
    // UIは表示されるが、商品名は表示されない
    expect(find.text('評価'), findsOneWidget);
    expect(find.text('レビュー本文'), findsOneWidget);
    expect(find.text('レビューを投稿する'), findsOneWidget);
  });
}
