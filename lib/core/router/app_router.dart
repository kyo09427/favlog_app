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
import '../../presentation/screens/settings_screen.dart'; // 追加
import '../../presentation/screens/single_review_screen.dart'; // 追加
import '../../presentation/screens/password_reset_request_screen.dart'; // 追加
import '../../presentation/screens/password_reset_email_sent_screen.dart'; // 追加
import '../../presentation/screens/update_password_screen.dart'; // 追加
import '../../presentation/screens/update_email_request_screen.dart'; // 追加
import '../../presentation/screens/update_email_sent_screen.dart'; // 追加
import '../../presentation/screens/confirm_email_change_screen.dart'; // 追加
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

// GoRouterのインスタンスを提供するRiverpodプロバイダー
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true, // デバッグ用にログを有効化
    refreshListenable: GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final authValue = authState.value;
      final loggedIn = authValue != null && authValue.session != null;

      // まだ認証状態が確定していない場合は何もしない
      if (authState.isLoading || authState.hasError) {
        return null;
      }

      // ログイン不要でアクセスできる公開ページ
      const publicRoutes = [
        '/auth',
        '/password-reset-request',
        '/password-reset-email-sent',
        '/reset-password',
      ];
      
      final currentLocation = state.matchedLocation;
      final isPublic = publicRoutes.contains(currentLocation);

      // --- ログイン状態に基づくリダイレクト ---

      // ① ログインしていない場合
      if (!loggedIn) {
        // 公開ページ以外は/authへ
        return isPublic ? null : '/auth';
      }

      // ② ログインしている場合

      // ②-a メール認証が済んでいない場合
      final emailVerified = authValue!.session?.user?.emailConfirmedAt != null;
      if (!emailVerified) {
        // メール認証ページ以外なら、メール認証ページへ
        return currentLocation == '/verify-email' ? null : '/verify-email';
      }

      // ②-b メール認証済みの場合
      // ログイン画面やメール認証画面にアクセスしようとしたら、ホームへリダイレクト
      if (currentLocation == '/auth' || currentLocation == '/verify-email') {
        return '/';
      }

      // 上記のいずれにも該当しない場合はリダイレクトしない
      return null;
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
          // Settings タブ (新規追加)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // ボトムナビゲーションバーの外に表示される画面
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/add-review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddReviewScreen(),
      ),
      GoRoute(
        path: '/product/:productId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ReviewDetailScreen(productId: productId);
        },
      ),
      // 新規追加ルート
      GoRoute(
        path: '/edit-review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final review = extra['review'] as Review;
          final product = extra['product'] as Product;
          return EditReviewScreen(review: review, product: product);
        },
      ),
      GoRoute(
        path: '/comment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final reviewId = extra['reviewId'] as String;
          final productName = extra['productName'] as String;
          return CommentScreen(reviewId: reviewId, productName: productName);
        },
      ),
      GoRoute(
        path: '/add-review-to-product',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final product = state.extra! as Product;
          return AddReviewToProductScreen(product: product);
        },
      ),
      // 個別レビュー詳細ページ
      GoRoute(
        path: '/review/:reviewId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final reviewId = state.pathParameters['reviewId']!;
          return SingleReviewScreen(reviewId: reviewId);
        },
      ),
      // パスワード変更関連
      GoRoute(
        path: '/password-reset-request',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: '/password-reset-email-sent',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PasswordResetEmailSentScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      // メールアドレス変更関連
      GoRoute(
        path: '/update-email-request',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpdateEmailRequestScreen(),
      ),
      GoRoute(
        path: '/update-email-sent',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpdateEmailSentScreen(),
      ),
      GoRoute(
        path: '/confirm-email-change',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConfirmEmailChangeScreen(),
      ),
    ],
  );
});