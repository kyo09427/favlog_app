import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/providers/category_providers.dart'; // Import categoryProvider
import 'package:favlog_app/presentation/providers/text_editing_controller_provider.dart'; // 今は使っていなくても残しておいてOK
import 'package:favlog_app/presentation/screens/add_review_screen.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/review_detail_screen.dart';
import 'package:favlog_app/presentation/screens/search_screen.dart'; // ★ 追加：検索画面
import 'package:favlog_app/domain/models/product.dart'; // Import Product model
import 'package:favlog_app/domain/models/review.dart'; // Import Review model
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart'; // Import for authRepositoryProvider
import 'dart:async'; // For Timer

// Helper widget for shimmer effect - moved outside the class
Widget _buildShimmerList() {
  return ListView.builder(
    itemCount: 5, // Show 5 shimmer items
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
                width: double.infinity,
                height: 16.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                height: 16.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                height: 16.0,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // HTML版の img.h-24 w-24 rounded-lg 相当のサムネイル
  Widget _buildThumbnail(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: imageUrl == null
            ? Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
      ),
    );
  }

  // 横並びのカードレイアウト（HTML に寄せた版）
  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    ProductWithLatestReview productWithReview,
  ) {
    final product = productWithReview.product;
    final latestReview = productWithReview.latestReview;
    final homeScreenController =
        ref.read(homeScreenControllerProvider.notifier);
    final homeScreenState = ref.watch(homeScreenControllerProvider);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReviewDetailScreen(productId: product.id),
          ),
        );
        // Refresh products after returning from detail screen
        homeScreenController.fetchProducts(
          category: homeScreenState.selectedCategory,
          searchQuery: homeScreenState.searchQuery,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        elevation: 0, // Tailwind風にフラットめ
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名
                    Text(
                      product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    // カテゴリ & サブカテゴリ（あれば）→ Chip で表示
                    if (product.category != null || product.subcategory != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (product.category != null)
                              Chip(
                                label: Text(
                                  product.category!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            if (product.subcategory != null)
                              Chip(
                                label: Text(
                                  product.subcategory!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.surfaceVariant,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 4),

                    // URL があれば薄く表示
                    if (product.url != null && product.url!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          product.url!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // レビュー部分
                    if (latestReview != null) ...[
                      Text(
                        'レビュー',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(height: 4),
                      // ReviewItem 自体はそのまま再利用（ロジックを変えない）
                      ReviewItem(
                        product: product,
                        review: latestReview,
                        onReviewEdited: () {
                          homeScreenController.fetchProducts(
                            category: homeScreenState.selectedCategory,
                            searchQuery: homeScreenState.searchQuery,
                          );
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      const Text(
                        'まだレビューがありません。',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeScreenState = ref.watch(homeScreenControllerProvider);
    final homeScreenController =
        ref.read(homeScreenControllerProvider.notifier);
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final authRepository = ref.read(authRepositoryProvider); // For logout

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューフィード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: 通知画面を作るならここで遷移
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepository.signOut();
            },
            tooltip: 'ログアウト',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72), // カテゴリ分だけ少し高さ
          child: Column(
            children: [
              // カテゴリ Dropdown のみ
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: categoriesAsyncValue.when(
                  data: (categories) {
                    final allCategories = categories; // categoriesProvider already includes 'すべて'
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
                      height: 48.0, // Approximate height of the dropdown
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
          ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: _buildShimmerList(),
            )
          : homeScreenState.error != null
              ? Center(child: Text('エラーが発生しました: ${homeScreenState.error}'))
              : homeScreenState.products.isEmpty
                  ? const Center(child: Text('まだレビューがありません。'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          // Use GridView for wider screens (tablets, web)
                          return GridView.builder(
                            itemCount: homeScreenState.products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.6, // 横長カードに少し合わせる
                            ),
                            itemBuilder: (context, index) {
                              final productWithReview =
                                  homeScreenState.products[index];
                              return _buildProductCard(
                                  context, ref, productWithReview);
                            },
                          );
                        } else {
                          // Use ListView for narrower screens (mobile)
                          return ListView.builder(
                            itemCount: homeScreenState.products.length,
                            itemBuilder: (context, index) {
                              final productWithReview =
                                  homeScreenState.products[index];
                              return _buildProductCard(
                                  context, ref, productWithReview);
                            },
                          );
                        }
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const AddReviewScreen()),
          );
          // Refresh products after returning from AddReviewScreen
          homeScreenController.fetchProducts(
            category: homeScreenState.selectedCategory,
            searchQuery: homeScreenState.searchQuery,
          );
        },
        child: const Icon(Icons.add),
      ),
      // HTMLの下部ボタンに相当する BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // 今はフィード固定
        selectedItemColor: Theme.of(context).colorScheme.primary,
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
