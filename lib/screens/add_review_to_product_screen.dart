import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/main.dart'; // For accessing the Supabase client

class AddReviewToProductScreen extends StatefulWidget {
  final Map<String, dynamic> product; // The existing product to review

  const AddReviewToProductScreen({super.key, required this.product});

  @override
  State<AddReviewToProductScreen> createState() => _AddReviewToProductScreenState();
}

class _AddReviewToProductScreenState extends State<AddReviewToProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewTextController = TextEditingController();
  double _rating = 3.0; // Default rating
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      // Insert review data
      await supabase.from('reviews').insert({
        'user_id': user.id,
        'product_id': widget.product['id'],
        'review_text': _reviewTextController.text,
        'rating': _rating.toInt(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを投稿しました！')),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューの投稿に失敗しました: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.product['name']} へのレビュー'),
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
                '商品名: ${widget.product['name']}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.product['category'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'カテゴリ: ${widget.product['category']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (widget.product['subcategory'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'サブカテゴリ: ${widget.product['subcategory']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (widget.product['image_url'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(
                    widget.product['image_url'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16.0),
              
              // Review input fields
              Text('評価: ${_rating.toInt()} / 5'),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.round().toString(),
                onChanged: (newRating) {
                  setState(() {
                    _rating = newRating;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _reviewTextController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'レビュー',
                  hintText: '商品の感想を書いてください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レビューを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitReview,
                      child: const Text('レビューを投稿'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}