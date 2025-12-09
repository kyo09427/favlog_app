import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/data/repositories/supabase_comment_repository.dart';
import 'package:favlog_app/data/repositories/supabase_like_repository.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/product_stats.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/domain/repositories/comment_repository.dart';
import 'package:favlog_app/domain/repositories/like_repository.dart';
import 'package:favlog_app/presentation/providers/category_providers.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart';
import 'package:favlog_app/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockLikeRepository extends Mock implements LikeRepository {}
class MockCommentRepository extends Mock implements CommentRepository {}

// Fake User for mocking
class FakeUser extends Fake implements User {
  @override
  String get id => 'test_user_id';
}

// A mock HomeScreenController that allows us to manually set the state
class MockHomeScreenController extends StateNotifier<HomeScreenState>
    implements HomeScreenController {
  MockHomeScreenController(super.state);

  @override
  Future<void> fetchProducts(
      {String? category = 'すべて',
      String? searchQuery,
      bool isRefresh = false,
      bool forceUpdate = false}) async {
    // Do nothing, state is controlled manually.
  }

  @override
  void selectCategory(String category) {
    // Do nothing, state is controlled manually.
  }

  @override
  Future<void> signOut() async {
    // Do nothing.
  }

  @override
  Future<void> refresh() async {
    // Do nothing.
  }

  @override
  void updateSearchQuery(String query) {
    // Do nothing.
  }
}

void main() {
  // Late variables for mocks, initialized in setUp
  late MockAuthRepository mockAuthRepository;
  late MockLikeRepository mockLikeRepository;
  late MockCommentRepository mockCommentRepository;

  // A helper function to wrap a widget with all necessary providers for testing
  Widget createTestWidget(
    Widget child,
    HomeScreenState initialState,
  ) {
    // Create a mock controller that we can control
    final mockController = MockHomeScreenController(initialState);

    return ProviderScope(
      overrides: [
        homeScreenControllerProvider.overrideWith((ref) => mockController),
        categoriesProvider.overrideWith((ref) => Future.value(['すべて', 'Book'])),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        likeRepositoryProvider.overrideWithValue(mockLikeRepository),
        commentRepositoryProvider.overrideWithValue(mockCommentRepository),
      ],
      child: MaterialApp(
        home: Scaffold(body: child), // Scaffold is needed for some widgets
      ),
    );
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockLikeRepository = MockLikeRepository();
    mockCommentRepository = MockCommentRepository();

    // Mock the auth repository to return a logged-in user for most tests
    when(() => mockAuthRepository.getCurrentUser()).thenReturn(FakeUser());
  });

  testWidgets('shows loading shimmer when state is loading and products are empty',
      (tester) async {
    // Arrange
    final initialState = HomeScreenState(isLoading: true, products: []);
    await tester.pumpWidget(createTestWidget(const HomeScreen(), initialState));

    // Assert
    expect(find.byType(Shimmer), findsWidgets);
  });

  testWidgets('shows empty message when there are no products and not loading',
      (tester) async {
    // Arrange
    final initialState = HomeScreenState(isLoading: false, products: []);
    await tester.pumpWidget(createTestWidget(const HomeScreen(), initialState));

    // pumpAndSettle to allow any futures to complete
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('まだレビューが投稿されていません'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('shows product list when products are available and not loading',
      (tester) async {
    // Arrange
    final product = Product(id: '1', createdAt: DateTime.now(), userId: 'a', name: 'Test Product', category: 'Book');
    final review = Review(id: 'r1', createdAt: DateTime.now(), userId: 'a', productId: '1', reviewText: 'Great!', rating: 5);
    final stats = ProductStats(productId: '1', averageRating: 5, reviewCount: 1);
    final productWithStats = ProductWithReviewAndStats(product: product, latestReview: review, stats: stats);

    final initialState = HomeScreenState(isLoading: false, products: [productWithStats]);

    // Mock dependencies for the _ReviewItemWithStats widget
    when(() => mockCommentRepository.getCommentsByReviewId(any())).thenAnswer((_) async => []);
    when(() => mockLikeRepository.getLikeCounts(any())).thenAnswer((_) async => {'r1': 0});
    when(() => mockLikeRepository.hasUserLiked(any(), any())).thenAnswer((_) async => false);

    await tester.pumpWidget(createTestWidget(const HomeScreen(), initialState));

    // This may require a pump to settle futures in _ReviewItemWithStats
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('まだレビューが投稿されていません'), findsNothing);
    // The list could be a ListView or GridView depending on screen size
    expect(find.byWidgetPredicate((widget) => widget is ListView || widget is GridView), findsOneWidget);
  });
}
