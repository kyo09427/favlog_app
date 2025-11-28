import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/providers/category_providers.dart'; // Import categoryProvider
import 'package:favlog_app/presentation/providers/text_editing_controller_provider.dart'; // Import the new provider
import 'package:favlog_app/presentation/screens/add_review_screen.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/review_detail_screen.dart';
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

  // Extracted product card widget to avoid duplication
  Widget _buildProductCard(BuildContext context, WidgetRef ref, ProductWithLatestReview productWithReview) {
    final product = productWithReview.product;
    final latestReview = productWithReview.latestReview;
    final homeScreenController = ref.read(homeScreenControllerProvider.notifier);
    final homeScreenState = ref.watch(homeScreenControllerProvider);


    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReviewDetailScreen(productId: product.id),
          ),
        );
        // Refresh products after returning from detail screen
        homeScreenController.fetchProducts(category: homeScreenState.selectedCategory, searchQuery: homeScreenState.searchQuery);
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (product.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 150),
                  ),
                ),
              if (product.url != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'URL: ${product.url}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (product.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'カテゴリ: ${product.category}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (product.subcategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'サブカテゴリ: ${product.subcategory}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 10),
              if (latestReview != null) ...[
                Text(
                  'レビュー:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ReviewItem(
                  product: product,
                  review: latestReview,
                  onReviewEdited: () {
                    homeScreenController.fetchProducts(category: homeScreenState.selectedCategory, searchQuery: homeScreenState.searchQuery);
                  },
                ),
              ] else ...[
                const Text(
                  'まだレビューがありません。',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeScreenState = ref.watch(homeScreenControllerProvider);
    final homeScreenController = ref.read(homeScreenControllerProvider.notifier);
    final categoriesAsyncValue = ref.watch(categoriesProvider); // Use categoriesProvider
    final searchController = ref.watch(homeSearchControllerProvider);
    final authRepository = ref.read(authRepositoryProvider); // For logout

    // Initialize search controller text with current state, only once
    if (searchController.text != homeScreenState.searchQuery) {
      searchController.text = homeScreenState.searchQuery;
      // Also update selection to put cursor at the end
      searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FavLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepository.signOut();
            },
            tooltip: 'ログアウト',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120), // Height extended for search bar
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '商品名で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: homeScreenState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              homeScreenController.updateSearchQuery(''); // Trigger search with empty query
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    homeScreenController.updateSearchQuery(value);
                  },
                ),
              ),
              
              // Existing Category Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: categoriesAsyncValue.when(
                  data: (categories) {
                    final allCategories = categories; // categoriesProvider already includes 'すべて'
                    return DropdownButtonFormField<String>(
                      value: homeScreenState.selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリで絞り込み',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                      items: allCategories.map<DropdownMenuItem<String>>((String category) {
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
                  error: (error, stack) => Center(child: Text('Error loading categories: $error')),
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8, // Adjust as needed
                            ),
                            itemBuilder: (context, index) {
                              final productWithReview = homeScreenState.products[index];
                              return _buildProductCard(context, ref, productWithReview);
                            },
                          );
                        } else {
                          // Use ListView for narrower screens (mobile)
                          return ListView.builder(
                            itemCount: homeScreenState.products.length,
                            itemBuilder: (context, index) {
                              final productWithReview = homeScreenState.products[index];
                              return _buildProductCard(context, ref, productWithReview);
                            },
                          );
                        }
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddReviewScreen()),
          );
          // Refresh products after returning from AddReviewScreen
          homeScreenController.fetchProducts(category: homeScreenState.selectedCategory, searchQuery: homeScreenState.searchQuery);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}