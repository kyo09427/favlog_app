import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart';
import 'package:favlog_app/presentation/providers/category_providers.dart';
import 'package:favlog_app/presentation/screens/add_review_screen.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/review_detail_screen.dart';
import 'package:favlog_app/presentation/screens/search_screen.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // サムネイル画像
  Widget _buildThumbnail(dynamic imageUrl) {
    final String? url =
        (imageUrl is String && imageUrl.isNotEmpty) ? imageUrl : null;

    if (url == null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 96,
            height: 96,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, _, __) => Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // ローディング時のシマー
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    height: 150.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: 120.0,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    height: 40.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeScreenState = ref.watch(homeScreenControllerProvider);
    final homeScreenController =
        ref.read(homeScreenControllerProvider.notifier);
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF4CAF50); // 落ち着いた緑色

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1B5E20)
            : primaryColor,
        title: const Text(
          'FavLog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // TODO: 通知画面を作るならここで遷移
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            children: [
              // カテゴリ Dropdown
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: categoriesAsyncValue.when(
                  data: (categories) {
                    final allCategories = categories;
                    return DropdownButtonFormField<String>(
                      value: homeScreenState.selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリで絞り込み',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                      items: allCategories
                          .map<DropdownMenuItem<String>>((String category) {
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
                  loading: () => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 48.0,
                      color: Colors.white,
                    ),
                  ),
                  error: (error, stack) =>
                      Center(child: Text('Error loading categories: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: homeScreenState.isLoading
          ? _buildLoadingShimmer()
          : homeScreenState.error != null
              ? Center(
                  child: Text('エラーが発生しました: ${homeScreenState.error}'))
              : homeScreenState.products.isEmpty
                  ? const Center(
                      child: Text('まだレビューが投稿されていません。'),
                    )
                  : ListView.builder(
                      itemCount: homeScreenState.products.length,
                      itemBuilder: (context, index) {
                        final item = homeScreenState.products[index];
                        // ProductWithLatestReview を想定: product / latestReview を持つ
                        final product = item.product;
                        final latestReview = item.latestReview;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.2),
                            ),
                          ),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // 詳細画面へ: productId を渡す
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReviewDetailScreen(
                                    productId: product.id,
                                  ),
                                ),
                              );
                              // 詳細画面から戻った後、リフレッシュ
                              homeScreenController.fetchProducts(
                                category: homeScreenState.selectedCategory,
                                searchQuery: homeScreenState.searchQuery,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildThumbnail(product.imageUrl),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // 商品名
                                            Text(
                                              product.name,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),

                                            // カテゴリ & サブカテゴリ(あれば)
                                            if (product.category != null ||
                                                product.subcategory != null)
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: [
                                                  if (product.category != null)
                                                    Chip(
                                                      label: Text(
                                                        product.category!,
                                                        style: theme.textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor: theme
                                                          .colorScheme.primary
                                                          .withOpacity(0.8),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4,
                                                      ),
                                                    ),
                                                  if (product.subcategory !=
                                                      null)
                                                    Chip(
                                                      label: Text(
                                                        product.subcategory!,
                                                        style: theme.textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor: theme
                                                          .colorScheme.secondary
                                                          .withOpacity(0.8),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4,
                                                      ),
                                                    ),
                                                ],
                                              ),

                                            const SizedBox(height: 8),

                                            // URL(あれば)
                                            if (product.url != null &&
                                                product.url!.isNotEmpty)
                                              Text(
                                                product.url!,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.blue,
                                                  decoration: TextDecoration
                                                      .underline,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                            const SizedBox(height: 8),

                                            // 星評価(0.5刻み表示): AddReviewScreen と同じロジック
                                            if (latestReview != null)
                                              RatingStars(
                                                rating: (latestReview.rating ??
                                                        0)
                                                    .toDouble(),
                                                color: primaryColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),

                                  const Text(
                                    '最新のレビュー',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  if (latestReview != null)
                                    ReviewItem(
                                      product: product,
                                      review: latestReview,
                                      onReviewEdited: () {
                                        homeScreenController.fetchProducts(
                                          category:
                                              homeScreenState.selectedCategory,
                                          searchQuery:
                                              homeScreenState.searchQuery,
                                        );
                                      },
                                    )
                                  else
                                    const Text(
                                      'まだレビューがありません。',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddReviewScreen(),
            ),
          );

          if (result == true) {
            homeScreenController.fetchProducts(
              category: homeScreenState.selectedCategory,
              searchQuery: homeScreenState.searchQuery,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      // 下部ナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          switch (index) {
            case 0:
              // フィード: 今の画面なので何もしない
              break;
            case 1:
              // 🔍 検索タブ → SearchScreen へ遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
              break;
            case 2:
              // TODO: プロフィール画面へ
              break;
            case 3:
              // TODO: 設定画面へ
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'フィード',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

/// 0.5刻みで表示する星ウィジェット(表示専用)
class RatingStars extends StatelessWidget {
  final double rating;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.color,
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

        return Icon(
          icon,
          size: 20,
          color: iconColor,
        );
      }),
    );
  }
}