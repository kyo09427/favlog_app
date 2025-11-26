import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/main.dart'; // For accessing the global Supabase client
import 'package:favlog_app/widgets/review_item.dart'; // New import
import 'package:favlog_app/screens/add_review_to_product_screen.dart'; // New import

class ReviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ReviewDetailScreen({super.key, required this.product});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchReviewsForProduct(widget.product['id']);
  }

  Future<List<Map<String, dynamic>>> _fetchReviewsForProduct(String productId) async {
    final response = await supabase
        .from('reviews')
        .select('id, user_id, review_text, rating, created_at')
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    // We fetch reviews again here to ensure fresh data after potential edits
    // This is a simplified approach. A more robust solution might involve
    // passing a refresh callback or using a state management solution.
    // For now, let's keep it simple.
    
    // final reviews = product['reviews'] as List<dynamic>; // No longer needed directly from widget.product

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product['image_url'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(
                  widget.product['image_url'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Text(
              widget.product['name'],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (widget.product['url'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'URL: ${widget.product['url']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            if (widget.product['category'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'カテゴリ: ${widget.product['category']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (widget.product['subcategory'] != null) // New: display subcategory
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'サブカテゴリ: ${widget.product['subcategory']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('レビューの読み込みエラー: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('まだレビューがありません。');
                }

                final reviews = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'レビュー (${reviews.length}件):',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    ...reviews.map((review) {
                      return ReviewItem(
                        product: widget.product, // Pass the whole product object
                        review: review,   // Pass the individual review object
                        supabaseClient: supabase, // Use the global supabase client
                        onReviewEdited: () {
                          // Refresh reviews after returning from edit screen
                          setState(() {
                            _reviewsFuture = _fetchReviewsForProduct(widget.product['id']);
                          });
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddReviewToProductScreen(product: widget.product),
            ),
          );
          // Refresh reviews after returning from AddReviewToProductScreen
          setState(() {
            _reviewsFuture = _fetchReviewsForProduct(widget.product['id']);
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