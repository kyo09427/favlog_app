import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart';
import 'package:favlog_app/presentation/providers/category_providers.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:shimmer/shimmer.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = ref.read(homeScreenControllerProvider.notifier);
        final state = ref.read(homeScreenControllerProvider);
        controller.fetchProducts(
          category: state.selectedCategory,
          searchQuery: state.searchQuery,
          forceUpdate: true,
        );
      }
    });
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
          errorWidget: (context, _, __) => Container(
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
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // context.push()ではなくcontext.go()を使用してURLを更新
          context.go('/product/${product.id}');
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
                        if (product.category != null || product.subcategory != null)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (product.category != null)
                                _buildChip(
                                  product.category!,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                  Colors.white,
                                  theme,
                                ),
                              if (product.subcategory != null)
                                _buildChip(
                                  product.subcategory!,
                                  theme.colorScheme.secondary.withOpacity(0.8),
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
                ReviewItem(
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
        title: const Text(
          'FavLog',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知機能は準備中です')),
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
                if (mounted) {
                  context.go('/auth');
                }
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: categoriesAsyncValue.when(
              data: (categories) {
                final isDark = theme.brightness == Brightness.dark;
                return DropdownButtonFormField<String>(
                  initialValue: homeScreenState.selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'カテゴリで絞り込み',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    filled: true,
                    fillColor: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.9),
                  ),
                  dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                  items: categories.map<DropdownMenuItem<String>>((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      homeScreenController.selectCategory(newValue);
                    }
                  },
                );
              },
              loading: () {
                final isDark = theme.brightness == Brightness.dark;
                return Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 48.0,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                );
              },
              error: (error, stack) => Container(
                height: 48,
                alignment: Alignment.center,
                child: Text(
                  'カテゴリ読込エラー',
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await context.push<bool>('/add-review');

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
