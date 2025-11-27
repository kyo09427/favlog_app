import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart'; // Import Product model
import 'package:favlog_app/presentation/providers/add_review_to_product_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/widgets/error_dialog.dart'; // Add this import

class AddReviewToProductScreen extends ConsumerWidget { // Change to ConsumerWidget
  final Product product; // The existing product to review

  const AddReviewToProductScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef ref
    final addReviewToProductState = ref.watch(addReviewToProductControllerProvider(product));
    final addReviewToProductController = ref.read(addReviewToProductControllerProvider(product).notifier);

    final _formKey = GlobalKey<FormState>();

    // Listen for error changes
    ref.listen<AddReviewToProductState>(
      addReviewToProductControllerProvider(product),
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${product.name} へのレビュー'), // Use product model
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display product info (non-editable)
              Text(
                '商品名: ${product.name}', // Use product model
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (product.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'カテゴリ: ${product.category}', // Use product model
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (product.subcategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'サブカテゴリ: ${product.subcategory}', // Use product model
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (product.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(
                    product.imageUrl!, // Use product model
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16.0),
              
              // Review input fields
              Text('評価: ${addReviewToProductState.rating.toInt()} / 5'),
              Slider(
                value: addReviewToProductState.rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: addReviewToProductState.rating.round().toString(),
                onChanged: (newRating) {
                  addReviewToProductController.updateRating(newRating);
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: addReviewToProductState.reviewText,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'レビュー',
                  hintText: '商品の感想を書いてください',
                  border: OutlineInputBorder(),
                ),
                onChanged: addReviewToProductController.updateReviewText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レビューを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              addReviewToProductState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await addReviewToProductController.submitReview();
                          if (context.mounted && addReviewToProductState.error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('レビューを投稿しました！')),
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('レビューを投稿'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}