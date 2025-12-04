import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart'; // 追加
import '../../domain/models/review.dart'; // 追加
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/search_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/review_detail_screen.dart';
import '../../presentation/screens/email_verification_screen.dart';
import '../../presentation/screens/add_review_screen.dart';
import '../../presentation/screens/edit_review_screen.dart'; // 追加
import '../../presentation/screens/comment_screen.dart'; // 追加
import '../../presentation/screens/add_review_to_product_screen.dart'; // 追加
import '../../presentation/widgets/scaffold_with_nav_bar.dart';

// StreamをリッスンしてGoRouterをリフレッシュするためのChangeNotifier
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// GoRouterのインスタンスを提供するRiverpodプロバイダー
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true, // デバッグ用にログを有効化
    refreshListenable: GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authState.value?.session != null;
      
      // まだ認証状態が確定していない場合は何もしない
      if (authState.isLoading || authState.hasError) {
        return null;
      }
      
      final isAuthRoute = state.matchedLocation == '/auth';

      // ログインしておらず、認証関連のルートでもない場合は、ログインページにリダイレクト
      if (!loggedIn && !isAuthRoute) {
        return '/auth';
      }

      // ログインしている場合
      if (loggedIn) {
        final emailVerified = authState.value?.session?.user?.emailConfirmedAt != null;
        final isVerifyingEmail = state.matchedLocation == '/verify-email';
        
        // メール認証が済んでいない場合
        if (!emailVerified) {
          return isVerifyingEmail ? null : '/verify-email';
        }

        // メール認証済みで、認証関連のページにいる場合はホームにリダイレクト
        if (isAuthRoute || isVerifyingEmail) {
          return '/';
        }
      }

      return null; // リダイレクトしない場合はnullを返す
    },
    routes: [
      // ボトムナビゲーションバーを持つStatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home タブ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Search タブ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Profile タブ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // ボトムナビゲーションバーの外に表示される画面
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/add-review',
        builder: (context, state) => const AddReviewScreen(),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ReviewDetailScreen(productId: productId);
        },
      ),
      // 新規追加ルート
      GoRoute(
        path: '/edit-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final review = extra['review'] as Review;
          final product = extra['product'] as Product;
          return EditReviewScreen(review: review, product: product);
        },
      ),
      GoRoute(
        path: '/comment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final reviewId = extra['reviewId'] as String;
          final productName = extra['productName'] as String;
          return CommentScreen(reviewId: reviewId, productName: productName);
        },
      ),
      GoRoute(
        path: '/add-review-to-product',
        builder: (context, state) {
          final product = state.extra! as Product;
          return AddReviewToProductScreen(product: product);
        },
      ),
    ],
  );
});