import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/home_screen_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/providers/category_providers.dart'; // Import categoryProvider
import 'package:favlog_app/presentation/screens/add_review_screen.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/review_detail_screen.dart';
import 'package:favlog_app/domain/models/product.dart'; // Import Product model
import 'package:favlog_app/domain/models/review.dart'; // Import Review model

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeScreenState = ref.watch(homeScreenControllerProvider);
    final homeScreenController = ref.read(homeScreenControllerProvider.notifier);
    final categoriesAsyncValue = ref.watch(categoriesProvider); // Use categoriesProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('FavLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await homeScreenController.signOut();
            },
            tooltip: 'ログアウト',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
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
                  items: allCategories.map<DropdownMenuItem<String>>((String category) { // Explicitly type map
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error loading categories: $error')),
            ),
          ),
        ),
      ),
      body: homeScreenState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : homeScreenState.error != null
              ? Center(child: Text('エラーが発生しました: ${homeScreenState.error}'))
              : homeScreenState.products.isEmpty
                  ? const Center(child: Text('まだレビューがありません。'))
                  : ListView.builder(
                      itemCount: homeScreenState.products.length,
                      itemBuilder: (context, index) {
                        final productWithReview = homeScreenState.products[index];
                        final product = productWithReview.product;
                        final latestReview = productWithReview.latestReview;

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ReviewDetailScreen(product: product),
                              ),
                            );
                            // Refresh products after returning from detail screen
                            homeScreenController.fetchProducts(category: homeScreenState.selectedCategory);
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
                                      child: Image.network(
                                        product.imageUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
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
                                        homeScreenController.fetchProducts(category: homeScreenState.selectedCategory);
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
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddReviewScreen()),
          );
          // Refresh products after returning from AddReviewScreen
          homeScreenController.fetchProducts(category: homeScreenState.selectedCategory);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}