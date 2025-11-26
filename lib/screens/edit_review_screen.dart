import 'dart:convert'; // For jsonDecode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/main.dart'; // For accessing the Supabase client

class EditReviewScreen extends StatefulWidget {
  final Map<String, dynamic> product; // Product data including image_url
  final Map<String, dynamic> review; // Review data

  const EditReviewScreen({super.key, required this.product, required this.review});

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productUrlController;
  late TextEditingController _productNameController;
  late TextEditingController _subcategoryController; // New controller for subcategory
  late String _selectedCategory; // State variable for selected category

  List<String> _categories = ['選択してください']; // Default categories

  late TextEditingController _reviewTextController;
  late double _rating;
  File? _imageFile; // New image selected by user
  String? _currentImageUrl; // Existing image URL
  bool _isLoading = false;
  bool _isPickingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories from JSON

    _productUrlController = TextEditingController(text: widget.product['url']);
    _productNameController = TextEditingController(text: widget.product['name']);
    _subcategoryController = TextEditingController(text: widget.product['subcategory']); // Initialize subcategory
    _reviewTextController = TextEditingController(text: widget.review['review_text']);
    _rating = (widget.review['rating'] as int).toDouble();
    _currentImageUrl = widget.product['image_url'];

    // Initialize _selectedCategory based on existing product category or default
    _selectedCategory = _categories.contains(widget.product['category'])
        ? widget.product['category']
        : _categories[0];
  }

  // New method to load categories from assets
  Future<void> _loadCategories() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    final data = await json.decode(response);
    setState(() {
      _categories = List<String>.from(data['categories']);
    });
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _currentImageUrl = null; // Clear current image if new one is picked
        });
      }
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _updateReview() async {
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

      String? newImageUrl = _currentImageUrl; // Start with existing image URL

      // 1. Upload new image if selected
      if (_imageFile != null) {
        final imageExtension = _imageFile!.path.split('.').last;
        final imageFileName = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$imageExtension';
        final imageBytes = await _imageFile!.readAsBytes();

        await supabase.storage.from('product_images').uploadBinary(
              imageFileName,
              imageBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                cacheControl: '3600',
              ),
            );
        newImageUrl = supabase.storage.from('product_images').getPublicUrl(imageFileName);

        // Optionally delete old image from storage if it exists
        // This requires more complex logic to track old image names
      } else if (_currentImageUrl == null && widget.product['image_url'] != null) {
        // If no new image picked, but current image was cleared (user action),
        // we might want to delete the old image from storage and set newImageUrl to null.
        // For simplicity, let's assume if _imageFile is null and _currentImageUrl is null,
        // it means user wants to remove image.
        newImageUrl = null;
      }


      // 2. Update product data
      await supabase.from('products').update({
        'url': _productUrlController.text.isEmpty ? null : _productUrlController.text,
        'name': _productNameController.text,
        'category': _selectedCategory == '選択してください' ? null : _selectedCategory, // Use _selectedCategory
        'subcategory': _subcategoryController.text.isEmpty ? null : _subcategoryController.text, // Save subcategory
        'image_url': newImageUrl, // Update with new or cleared image URL
      }).eq('id', widget.product['id']);

      // 3. Update review data
      await supabase.from('reviews').update({
        'review_text': _reviewTextController.text,
        'rating': _rating.toInt(),
      }).eq('id', widget.review['id']);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを更新しました！')),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューの更新に失敗しました: $error')),
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
    _productUrlController.dispose();
    _productNameController.dispose();
    _subcategoryController.dispose(); // Dispose subcategory controller
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '商品名を入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _productUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '商品URL (オプション)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value == '選択してください') {
                    return 'カテゴリを選択してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _subcategoryController,
                decoration: const InputDecoration(
                  labelText: 'サブカテゴリ (オプション)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (_currentImageUrl != null
                          ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                          : const Text('画像をタップして選択 (オプション)')),
                ),
              ),
              const SizedBox(height: 16.0),
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
                      onPressed: _updateReview,
                      child: const Text('レビューを更新'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}