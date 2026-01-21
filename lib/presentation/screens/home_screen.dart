import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart';
import 'package:favlog_app/presentation/providers/category_providers.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/domain/models/review_stats.dart';
import 'package:favlog_app/data/repositories/supabase_comment_repository.dart';
import 'package:favlog_app/data/repositories/supabase_like_repository.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/core/providers/notification_providers.dart';
import 'package:favlog_app/presentation/providers/announcement_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 不要な再取得を削除 - PageStorageの動作を妨げないため
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      // TODO: ページネーション実装時にここで次ページを読み込む
    }
  }

  Widget _buildThumbnail(dynamic imageUrl, {double size = 96}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String? url = (imageUrl is String && imageUrl.isNotEmpty) ? imageUrl : null;

    if (url == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: size * 0.4,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholder: (context, _) => Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              width: size,
              height: size,
              color: isDark ? Colors.grey[800] : Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.broken_image,
              size: size * 0.4,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        key: const PageStorageKey('home_list'),
        controller: _scrollController,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20.0,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    height: 150.0,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: 120.0,
                    height: 20.0,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, ProductWithReviewAndStats item) {
    final theme = Theme.of(context);
    final product = item.product;
    final latestReview = item.latestReview;
    final stats = item.stats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // context.push()を使用してナビゲーションスタックを保持
          context.push('/product/${product.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(product.imageUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (product.category != null || product.subcategoryTags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (product.category != null)
                                _buildChip(
                                  product.category!,
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
                                  Colors.white,
                                  theme,
                                ),
                              if (product.subcategoryTags.isNotEmpty)
                                _buildChip(
                                  product.subcategoryTags.first,
                                  theme.colorScheme.secondary.withValues(alpha: 0.8),
                                  Colors.white,
                                  theme,
                                ),
                            ],
                          ),
                        if (stats.reviewCount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RatingStars(
                                rating: stats.averageRating,
                                color: const Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${stats.averageRating.toStringAsFixed(1)} (${stats.reviewCount})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              const Text(
                '最新のレビュー',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (latestReview != null)
                _ReviewItemWithStats(
                  product: product,
                  review: latestReview,
                )
              else
                const Text(
                  'まだレビューがありません。',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor, ThemeData theme) {
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: textColor),
      ),
      backgroundColor: bgColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<String>> categoriesAsyncValue,
    String selectedCategory,
    HomeScreenController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return categoriesAsyncValue.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: categories.map((category) {
            final isSelected = category == selectedCategory;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => controller.selectCategory(category),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      loading: () => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: 48.0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      error: (error, stack) => Container(
        height: 48,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          'カテゴリ読込エラー',
          style: TextStyle(color: Colors.red[300]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeScreenState = ref.watch(homeScreenControllerProvider);
    final homeScreenController = ref.read(homeScreenControllerProvider.notifier);
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF4CAF50);

    ref.listen<HomeScreenState>(
      homeScreenControllerProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: '再試行',
                  textColor: Colors.white,
                  onPressed: () {
                    homeScreenController.fetchProducts(
                      category: next.selectedCategory,
                      searchQuery: next.searchQuery,
                      forceUpdate: true,
                    );
                  },
                ),
              ),
            );
          }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1B5E20)
            : primaryColor,
        leading: Consumer(
          builder: (context, ref, child) {
            final unreadCountAsync = ref.watch(unreadAnnouncementCountProvider);
            
            return unreadCountAsync.when(
              data: (count) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    onPressed: () {
                      context.push('/announcements');
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              loading: () => IconButton(
                icon: const Icon(Icons.campaign, color: Colors.white),
                onPressed: () {
                  context.push('/announcements');
                },
              ),
              error: (_, __) => IconButton(
                icon: const Icon(Icons.campaign, color: Colors.white),
                onPressed: () {
                  context.push('/announcements');
                },
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'FavLog',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
              
              return unreadCountAsync.when(
                data: (count) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {
                    context.push('/notifications');
                  },
                ),
                error: (_, _) => IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {
                    context.push('/notifications');
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
               content: const Text('本当にログアウトしますか?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => context.pop(true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && mounted) {
                await homeScreenController.signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(
            context,
            ref,
            categoriesAsyncValue,
            homeScreenState.selectedCategory,
            homeScreenController,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await homeScreenController.fetchProducts(
                  category: homeScreenState.selectedCategory,
                  searchQuery: homeScreenState.searchQuery,
                  isRefresh: true,
                );
              },
              child: homeScreenState.isLoading && homeScreenState.products.isEmpty
                  ? _buildLoadingShimmer()
                  : homeScreenState.products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'まだレビューが投稿されていません',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '右下の + ボタンから投稿してみましょう!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return GridView.builder(
                                key: const PageStorageKey('home_grid'),
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: homeScreenState.products.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(
                                    context,
                                    homeScreenState.products[index],
                                  );
                                },
                              );
                            } else {
                              return ListView.builder(
                                key: const PageStorageKey('home_list'),
                                controller: _scrollController,
                                itemCount: homeScreenState.products.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(
                                    context,
                                    homeScreenState.products[index],
                                  );
                                },
                              );
                            }
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await context.push<bool>('/product-selection');

          if (result == true && mounted) {
            homeScreenController.fetchProducts(
              category: homeScreenState.selectedCategory,
              searchQuery: homeScreenState.searchQuery,
              forceUpdate: true,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final Color? color;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = color ?? const Color(0xFF4CAF50);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = rating >= starIndex;
        final isHalf = rating >= starIndex - 0.5 && rating < starIndex;

        IconData icon;
        Color iconColor;

        if (isFilled) {
          icon = Icons.star;
          iconColor = starColor;
        } else if (isHalf) {
          icon = Icons.star_half;
          iconColor = starColor;
        } else {
          icon = Icons.star_border;
          iconColor = theme.brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[400]!;
        }

        return Icon(icon, size: size, color: iconColor);
      }),
    );
  }
}

// ReviewItemをラップしてstatsを提供するウィジェット
class _ReviewItemWithStats extends ConsumerStatefulWidget {
  final Product product;
  final Review review;

  const _ReviewItemWithStats({
    required this.product,
    required this.review,
  });

  @override
  ConsumerState<_ReviewItemWithStats> createState() => _ReviewItemWithStatsState();
}

class _ReviewItemWithStatsState extends ConsumerState<_ReviewItemWithStats> {
  int? _likeCount;
  int? _commentCount;
  bool? _isLiked;
  bool _isInitialized = false;

  @override
  void didUpdateWidget(_ReviewItemWithStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.review != oldWidget.review) {
      final commentRepository = ref.read(commentRepositoryProvider);
      final likeRepository = ref.read(likeRepositoryProvider);
      final currentUser = ref.read(authRepositoryProvider).getCurrentUser();

      if (currentUser != null) {
        _loadInitialData(commentRepository, likeRepository, currentUser.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentRepository = ref.watch(commentRepositoryProvider);
    final likeRepository = ref.watch(likeRepositoryProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    final currentUser = authRepository.getCurrentUser();

    if (currentUser == null) {
      return ReviewItem(
        product: widget.product,
        review: widget.review,
      );
    }

    // 初回のみデータを取得
    if (!_isInitialized) {
      _loadInitialData(commentRepository, likeRepository, currentUser.id);
    }

    // ローカル状態を使用
    final likeCount = _likeCount ?? 0;
    final commentCount = _commentCount ?? 0;
    final isLiked = _isLiked ?? false;

    final stats = ReviewStats(
      reviewId: widget.review.id,
      likeCount: likeCount,
      commentCount: commentCount,
    );

    return ReviewItem(
      product: widget.product,
      review: widget.review,
      stats: stats,
      isLiked: isLiked,
      onLikeToggle: () => _toggleLike(likeRepository, isLiked),
      onCommentTap: () {
        context.push(
          '/comment',
          extra: {
            'reviewId': widget.review.id,
            'productName': widget.product.name,
          },
        );
      },
    );
  }

  Future<void> _loadInitialData(
    dynamic commentRepository,
    dynamic likeRepository,
    String userId,
  ) async {
    try {
      final results = await Future.wait<dynamic>([
        commentRepository.getCommentsByReviewId(widget.review.id),
        likeRepository.getLikeCounts([widget.review.id]),
        likeRepository.hasUserLiked(widget.review.id, userId),
      ]);

      if (mounted) {
        setState(() {
          final comments = results[0] as List;
          final likes = results[1] as Map<String, int>;
          final liked = results[2] as bool;
          _commentCount = comments.length;
          _likeCount = likes[widget.review.id] ?? 0;
          _isLiked = liked;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentCount = 0;
          _likeCount = 0;
          _isLiked = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _toggleLike(dynamic likeRepository, bool currentlyLiked) async {
    try {
      // 楽観的UI更新（即座に反映）
      setState(() {
        if (currentlyLiked) {
          _isLiked = false;
          _likeCount = (_likeCount ?? 1) - 1;
        } else {
          _isLiked = true;
          _likeCount = (_likeCount ?? 0) + 1;
        }
      });

      // サーバーに送信
      if (currentlyLiked) {
        await likeRepository.removeLike(widget.review.id);
      } else {
        await likeRepository.addLike(widget.review.id);
      }
    } catch (e) {
      // エラー時は元に戻す
      if (mounted) {
        setState(() {
          if (currentlyLiked) {
            _isLiked = true;
            _likeCount = (_likeCount ?? 0) + 1;
          } else {
            _isLiked = false;
            _likeCount = (_likeCount ?? 1) - 1;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('いいねの操作に失敗しました: $e')),
        );
      }
    }
  }
}
