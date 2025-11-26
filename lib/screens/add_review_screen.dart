import 'dart:convert'; // For jsonDecode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/main.dart'; // For accessing the Supabase client

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productUrlController = TextEditingController();
  final _productNameController = TextEditingController();
  final _subcategoryController = TextEditingController(); // New controller for subcategory
  String _selectedCategory = '選択してください'; // State variable for selected category

  List<String> _categories = ['選択してください']; // Default categories

  final _reviewTextController = TextEditingController();
  double _rating = 3.0; // Default rating
  File? _imageFile;
  bool _isLoading = false;
  bool _isPickingImage = false; // New flag

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    final data = await json.decode(response);
    setState(() {
      _categories = List<String>.from(data['categories']);
    });
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) { // Prevent multiple calls
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
        });
      }
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }

  }

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

      // 1. Upload image to Supabase Storage
      String? imageUrl;
      if (_imageFile != null) {
        final imageExtension = _imageFile!.path.split('.').last;
        final imageFileName = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$imageExtension';
        final imageBytes = await _imageFile!.readAsBytes();

        final response = await supabase.storage.from('product_images').uploadBinary(
              imageFileName,
              imageBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg', // Or derive dynamically
                cacheControl: '3600',
              ),
            );
        imageUrl = supabase.storage.from('product_images').getPublicUrl(imageFileName);
      }

      // 2. Insert product data
      final productResponse = await supabase.from('products').insert({
        'user_id': user.id,
        'url': _productUrlController.text.isEmpty ? null : _productUrlController.text,
        'name': _productNameController.text,
        'category': _selectedCategory == '選択してください' ? null : _selectedCategory, // Use _selectedCategory
        'subcategory': _subcategoryController.text.isEmpty ? null : _subcategoryController.text, // Save subcategory
      }).select('id').single(); // Get the ID of the newly created product

      final productId = productResponse['id'];

      // 3. Insert review data
      await supabase.from('reviews').insert({
        'user_id': user.id,
        'product_id': productId,
        'review_text': _reviewTextController.text,
        'rating': _rating.toInt(),
      });

      // 4. Update product with image URL if available
      if (imageUrl != null) {
        await supabase.from('products').update({
          'image_url': imageUrl,
        }).eq('id', productId);
        print('Image uploaded and product updated with URL: $imageUrl');
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューと商品情報を追加しました！')),
        );
        // Optionally clear form or navigate back
        _productUrlController.clear();
        _productNameController.clear();
        _subcategoryController.clear(); // Clear subcategory controller
        _reviewTextController.clear();
        setState(() {
          _rating = 3.0;
          _imageFile = null;
          _selectedCategory = _categories[0]; // Reset selected category
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューの追加に失敗しました: $error')),
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
        title: const Text('レビューを追加'),
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
                  child: _imageFile == null
                      ? const Text('画像をタップして選択 (オプション)')
                      : Image.file(_imageFile!, fit: BoxFit.cover),
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