import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

import '../../domain/models/profile.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review_stats.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/repositories/like_repository.dart';
import '../providers/profile_screen_controller.dart';
import '../providers/profile_data_providers.dart';
import '../widgets/error_dialog.dart';
import '../widgets/review_item.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_comment_repository.dart';
import '../../data/repositories/supabase_like_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../core/providers/notification_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _likedReviews = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(String reviewId, bool currentlyLiked) async {
    final likeRepository = ref.read(likeRepositoryProvider);

    try {
      if (currentlyLiked) {
        await likeRepository.removeLike(reviewId);
        setState(() => _likedReviews[reviewId] = false);
      } else {
        await likeRepository.addLike(reviewId);
        setState(() => _likedReviews[reviewId] = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('いいねの操作に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レビューを削除'),
        content: const Text('このレビューを削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final reviewRepository = ref.read(reviewRepositoryProvider);
      await reviewRepository.deleteReview(reviewId);
      
      if (mounted) {
        // プロバイダーを無効化してキャッシュを更新
        final authRepository = ref.read(authRepositoryProvider);
        final currentUserId = authRepository.getCurrentUser()?.id;
        if (currentUserId != null) {
          ref.invalidate(userReviewsProvider(currentUserId));
          ref.invalidate(userLikedReviewIdsProvider(currentUserId));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileScreenControllerProvider);
    final profileController = ref.read(profileScreenControllerProvider.notifier);
    final reviewRepository = ref.watch(reviewRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF13ec5b);
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    ref.listen<AsyncValue<Profile?>>(profileScreenControllerProvider, (previous, next) {
      if (!next.isLoading && next.hasError) {
        ErrorDialog.show(context, 'プロフィールの更新に失敗しました: ${next.error}');
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'プロフィールを準備中...',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            );
          }

          final authRepository = ref.read(authRepositoryProvider);
          final currentUserId = authRepository.getCurrentUser()?.id ?? '';

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: backgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'プロフィール',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
                actions: [
                  // 通知アイコン
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
                      
                      return unreadCountAsync.when(
                        data: (unreadCount) {
                          if (unreadCount > 0) {
                            return badges.Badge(
                              badgeContent: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              badgeStyle: const badges.BadgeStyle(
                                badgeColor: Colors.red,
                                padding: EdgeInsets.all(4),
                              ),
                              position: badges.BadgePosition.topEnd(top: 0, end: 3),
                              child: IconButton(
                                icon: Icon(Icons.notifications, color: textColor),
                                onPressed: () => context.push('/notifications'),
                              ),
                            );
                          }
                          return IconButton(
                            icon: Icon(Icons.notifications_none, color: textColor),
                            onPressed: () => context.push('/notifications'),
                          );
                        },
                        loading: () => IconButton(
                          icon: Icon(Icons.notifications_none, color: textColor),
                          onPressed: () => context.push('/notifications'),
                        ),
                        error: (_, _) => IconButton(
                          icon: Icon(Icons.notifications_none, color: textColor),
                          onPressed: () => context.push('/notifications'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: textColor),
                    onPressed: () {
                      _showEditProfileDialog(context, profile, profileController);
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // ユーザーアバター
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                        image: profile.avatarUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(profile.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[300],
                      ),
                      child: profile.avatarUrl == null
                          ? Icon(Icons.person, size: 64, color: Colors.grey[600])
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // ユーザー名とハンドル
                    Text(
                      profile.username,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 24),

                    // レビュー数統計
                    Consumer(
                      builder: (context, ref, child) {
                        final reviewsAsync = ref.watch(userReviewsProvider(currentUserId));
                        final reviewCount = reviewsAsync.valueOrNull?.length ?? 0;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Text(
                                reviewCount.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'レビュー',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // タブバー
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: textColor,
                        unselectedLabelColor: mutedTextColor,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'レビュー'),
                          Tab(text: 'いいね'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // タブビュー
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // レビュータブ
                    _buildReviewList(
                      currentUserId: currentUserId,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),

                    // いいねタブ
                    _buildLikedReviewList(
                      currentUserId: currentUserId,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'プロフィールの読み込みに失敗しました。',
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => profileController.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList({
    required String currentUserId,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final reviewsAsync = ref.watch(userReviewsProvider(currentUserId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'まだレビューがありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewItemOptimized(
              review: review,
              currentUserId: currentUserId,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF13ec5b)),
      ),
      error: (error, stack) => Center(
        child: Text(
          'レビューの読み込みに失敗しました',
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _buildLikedReviewList({
    required String currentUserId,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final likedReviewIdsAsync = ref.watch(userLikedReviewIdsProvider(currentUserId));
    final reviewRepository = ref.watch(reviewRepositoryProvider);

    return likedReviewIdsAsync.when(
      data: (likedReviewIds) {
        if (likedReviewIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'まだいいねしたレビューがありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: likedReviewIds.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final reviewId = likedReviewIds[index];
            return FutureBuilder<Review>(
              future: reviewRepository.getReviewById(reviewId),
              builder: (context, reviewSnapshot) {
                if (!reviewSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                final review = reviewSnapshot.data!;
                return _buildReviewItemOptimized(
                  review: review,
                  currentUserId: currentUserId,
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF13ec5b)),
      ),
      error: (error, stack) => Center(
        child: Text(
          'いいねしたレビューの読み込みに失敗しました',
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  /// プロバイダーを使用した最適化されたレビューアイテム表示
  Widget _buildReviewItemOptimized({
    required Review review,
    required String currentUserId,
  }) {
    // 商品情報を取得
    final productAsync = ref.watch(productProvider(review.productId));
    // レビュー統計を取得
    final statsAsync = ref.watch(reviewStatsProvider(review.id));
    // いいね状態を取得
    final isLikedAsync = ref.watch(reviewLikeStatusProvider((reviewId: review.id, userId: currentUserId)));

    // いずれかがローディング中の場合
    if (productAsync.isLoading ||statsAsync.isLoading || isLikedAsync.isLoading) {
      return const SizedBox.shrink();
    }

    // いずれかにエラーがある場合
    if (productAsync.hasError || statsAsync.hasError || isLikedAsync.hasError) {
      return const SizedBox.shrink();
    }

    final product = productAsync.value;
    final stats = statsAsync.value;
    final isLiked = _likedReviews[review.id] ?? (isLikedAsync.value ?? false);

    if (product == null || stats == null) {
      return const SizedBox.shrink();
    }

    return ReviewItem(
      product: product,
      review: review,
      stats: stats,
      isLiked: isLiked,
      onLikeToggle: () => _toggleLike(review.id, isLiked),
      onCommentTap: () {
        context.push(
          '/comment',
          extra: {
            'reviewId': review.id,
            'productName': product.name,
          },
        );
      },
      onDelete: () => _deleteReview(review.id),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    Profile profile,
    ProfileScreenController controller,
  ) {
    final usernameController = TextEditingController(text: profile.username);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    const primaryColor = Color(0xFF13ec5b);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final profileState = ref.watch(profileScreenControllerProvider);
            final currentProfile = profileState.valueOrNull ?? profile;
            final isLoading = profileState.isLoading;

            // エラーハンドリング
            ref.listen<AsyncValue<Profile?>>(profileScreenControllerProvider, (previous, next) {
              if (!next.isLoading && next.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('エラー: ${next.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });

            return Scaffold(
              backgroundColor: backgroundColor,
              body: Column(
                children: [
                  // ヘッダー
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          // 戻るボタン
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: textColor,
                                size: 24,
                              ),
                            ),
                          ),
                          // タイトル
                          Expanded(
                            child: Text(
                              'プロフィールを編集',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),

                  // コンテンツ
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // アバター表示と変更ボタン
                        Column(
                          children: [
                            // アバター画像
                            Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryColor, width: 2),
                                    image: currentProfile.avatarUrl != null
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(currentProfile.avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey[300],
                                  ),
                                  child: currentProfile.avatarUrl == null
                                      ? Icon(Icons.person, size: 64, color: Colors.grey[600])
                                      : null,
                                ),
                                // ローディングインジケーター
                                if (isLoading)
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: isLoading ? null : () {
                                        controller.pickAndUploadAvatar();
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: isLoading ? null : () {
                                controller.pickAndUploadAvatar();
                              },
                              child: Text(
                                isLoading ? 'アップロード中...' : 'プロフィール画像を変更',
                                style: TextStyle(
                                  color: isLoading ? mutedTextColor : primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ユーザー名入力
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ユーザー名',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: usernameController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: 'ユーザー名を入力',
                                hintStyle: TextStyle(color: mutedTextColor),
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                      ],
                    ),
                  ),

                  // 保存ボタン（下部固定）
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                        top: BorderSide(color: borderColor),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            await controller.updateProfileDetails(
                              username: usernameController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
