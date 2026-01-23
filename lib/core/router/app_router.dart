import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/search_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/review_detail_screen.dart';
import '../../presentation/screens/email_verification_screen.dart';
import '../../presentation/screens/product_selection_screen.dart';
import '../../presentation/screens/add_product_screen.dart';
import '../../presentation/screens/add_review_screen.dart';
import '../../presentation/screens/edit_review_screen.dart';
import '../../presentation/screens/comment_screen.dart';
import '../../presentation/screens/add_review_to_product_screen.dart';
import '../../presentation/screens/edit_product_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/version_screen.dart';
import '../../presentation/screens/install_permission_guide_screen.dart';
import '../../presentation/screens/password_reset_request_screen.dart';
import '../../presentation/screens/password_reset_email_sent_screen.dart';
import '../../presentation/screens/update_password_screen.dart';
import '../../presentation/screens/update_email_request_screen.dart';
import '../../presentation/screens/update_email_sent_screen.dart';
import '../../presentation/screens/confirm_email_change_screen.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/announcements_screen.dart';
import '../../presentation/screens/announcement_detail_screen.dart';
import '../../presentation/screens/create_announcement_screen.dart';
import '../../presentation/screens/edit_announcement_screen.dart';
import '../../presentation/widgets/scaffold_with_nav_bar.dart';
import '../../domain/models/announcement.dart';

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
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true, // デバッグ用にログを有効化
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),
    redirect: (BuildContext context, GoRouterState state) async {
      final authState = await ref.watch(authStateChangesProvider.future);
      final loggedIn = authState.session != null;

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
        // 公開ページ以外なら/authへ
        return isPublic ? null : '/auth';
      }

      // ② ログインしている場合

      // authStateがnullでないことはloggedInチェックで保証されている
      final user = authState.session!.user;

      // ②-a メール認証が済んでいない場合
      final emailVerified = user.emailConfirmedAt != null;
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
      // ボトムナビゲーションバ�Eを持つStatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home タチE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Search タチE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Profile タチE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          // Settings タチE(新規追加)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'version',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const VersionScreen(),
                    routes: [
                      GoRoute(
                        path: 'permission-guide',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const InstallPermissionGuideScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ボトムナビゲーションバ�Eの外に表示される画面
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
      // 商品選択画面（レビュ投稿の最初のステップ）
      GoRoute(
        path: '/product-selection',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      // 新しい商品を追加する画面
      GoRoute(
        path: '/add-product',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddProductScreen(),
      ),
      // レビュー投稿画面（商品が選択された後）
      GoRoute(
        path: '/add-review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final product = extra?['product'] as Product?;
          return AddReviewScreen(selectedProduct: product);
        },
      ),
      GoRoute(
        path: '/product/:productId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ReviewDetailScreen(productId: productId);
        },
      ),
      // 新規追加ルーチE
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
      GoRoute(
        path: '/edit-product',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final product = state.extra! as Product;
          return EditProductScreen(product: product);
        },
      ),
      // 個別レビュー詳細ペ�Eジ
      GoRoute(
        path: '/review/:reviewId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final reviewId = state.pathParameters['reviewId']!;
          return CommentScreen(reviewId: reviewId, productName: '');
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
      // 通知画面
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // お知らせ一覧画面
      GoRoute(
        path: '/announcements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      // お知らせ作成画面（パス変数を含むルートより前に定義）
      GoRoute(
        path: '/announcements/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateAnnouncementScreen(),
      ),
      // お知らせ詳細画面
      GoRoute(
        path: '/announcements/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementDetailScreen(announcementId: id);
        },
      ),
      // お知らせ編集画面
      GoRoute(
        path: '/announcements/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final announcement = state.extra! as Announcement;
          return EditAnnouncementScreen(announcement: announcement);
        },
      ),
    ],
  );
});
