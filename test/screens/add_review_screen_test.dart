import 'package:favlog_app/core/providers/common_providers.dart';
import 'package:favlog_app/data/repositories/asset_category_repository.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/data/repositories/supabase_product_repository.dart';
import 'package:favlog_app/data/repositories/supabase_review_repository.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/domain/repositories/category_repository.dart';
import 'package:favlog_app/domain/repositories/product_repository.dart';
import 'package:favlog_app/domain/repositories/review_repository.dart';
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

  Widget createAddReviewScreen() {
    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepository),
        productRepositoryProvider.overrideWithValue(mockProductRepository),
        reviewRepositoryProvider.overrideWithValue(mockReviewRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        imageCompressorProvider.overrideWithValue(mockImageCompressor),
      ],
      child: const MaterialApp(home: AddReviewScreen()),
    );
  }

  testWidgets('AddReviewScreen renders correctly', (WidgetTester tester) async {
    // Mock the dependencies' methods
    when(() => mockCategoryRepository.getCategories()).thenAnswer((_) async => ['本', '家電']);

    await tester.pumpWidget(createAddReviewScreen());
    await tester.pumpAndSettle();

    // Header title
    expect(find.text('レビューを追加'), findsOneWidget);

    // Form field labels
    expect(find.text('商品名 *'), findsOneWidget);
    expect(find.text('URL（任意）'), findsOneWidget);
    expect(find.text('カテゴリ *'), findsOneWidget);
    expect(find.text('サブカテゴリ（任意）'), findsOneWidget);
    expect(find.text('評価 *'), findsOneWidget);
    expect(find.text('レビュー *'), findsOneWidget);

    // Submit button in custom header
    expect(find.text('投稿する'), findsOneWidget);
  });
}
