import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/screens/add_review_screen.dart';
import 'package:favlog_app/screens/edit_review_screen.dart';
import 'package:favlog_app/widgets/review_item.dart';
import 'package:favlog_app/screens/review_detail_screen.dart';
import 'package:favlog_app/main.dart';

class HomeScreen extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const HomeScreen({super.key, this.supabaseClient});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  late final SupabaseClient _supabase;

  List<String> _categories = ['すべて']; // Categories for filter dropdown
  String _selectedFilterCategory = 'すべて'; // Currently selected category for filtering

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? supabase;
    // Initialize _productsFuture immediately with a Future call
    _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);

    _loadCategories().then((_) {
      // If categories changed and filter is still default, refetch if needed
      if (_selectedFilterCategory == 'すべて' && _categories.length > 1) {
        setState(() {
          _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);
        });
      } else {
        setState(() {}); // Trigger rebuild to update dropdown items
      }
    });
  }

  // New method to load categories from assets
  Future<void> _loadCategories() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    final data = await json.decode(response);
    setState(() {
      _categories = ['すべて', ...List<String>.from(data['categories'])];
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProductsWithReviews(String? category) async {
    var query = _supabase
        .from('products')
        .select('id, name, url, category, subcategory, image_url, created_at');

    if (category != null && category != 'すべて') {
      query = query.eq('category', category);
    }

    final productResponse = await query.order('created_at', ascending: false);

    List<Map<String, dynamic>> productsWithLatestReview = [];
    for (var product in productResponse) {
      // Fetch only the latest review for this product
      final latestReview = await _supabase
          .from('reviews')
          .select('id, user_id, review_text, rating, created_at')
          .eq('product_id', product['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestReview != null) {
        productsWithLatestReview.add({...product, 'reviews': [latestReview]});
      } else {
        // If no reviews, we still want to show the product with no reviews
        productsWithLatestReview.add({...product, 'reviews': []});
      }
    }
    return productsWithLatestReview;
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予期せぬエラーが発生しました: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FavLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'ログアウト',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilterCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリで絞り込み',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilterCategory = newValue;
                    _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);
                  });
                }
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('まだレビューがありません。'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final reviews = product['reviews'] as List<dynamic>;

              return GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReviewDetailScreen(product: product),
                    ),
                  );
                  // Refresh products after returning from detail screen
                  setState(() {
                    _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);
                  });
                },
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (product['image_url'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.network(
                              product['image_url'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (product['url'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'URL: ${product['url']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (product['category'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'カテゴリ: ${product['category']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (product['subcategory'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'サブカテゴリ: ${product['subcategory']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (reviews.isNotEmpty) ...[
                          Text(
                            'レビュー:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ...reviews.map((review) {
                            return ReviewItem(
                              product: product,
                              review: review,
                              supabaseClient: _supabase,
                              onReviewEdited: () {
                                setState(() {
                                  _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);
                                });
                              },
                            );
                          }).toList(),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddReviewScreen()),
          );
          // Refresh products after returning from AddReviewScreen
          setState(() {
            _productsFuture = _fetchProductsWithReviews(_selectedFilterCategory);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension on DateTime {
  String toShortString() {
    return '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}