import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String? url;
  final String name;
  final String? category;
  final List<String> subcategoryTags; // 複数のサブカテゴリタグに変更
  final String? imageUrl;

  Product({
    String? id,
    DateTime? createdAt,
    required this.userId,
    this.url,
    required this.name,
    this.category,
    List<String>? subcategoryTags,
    this.imageUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        subcategoryTags = subcategoryTags ?? [];

  factory Product.empty() {
    return Product(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(),
      userId: '',
      url: null,
      name: '',
      category: null,
      subcategoryTags: [],
      imageUrl: null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      url: json['url'] as String?,
      name: json['name'] as String,
      category: json['category'] as String?,
      subcategoryTags: json['subcategory_tags'] != null
          ? List<String>.from(json['subcategory_tags'] as List)
          : (json['subcategory'] != null ? [json['subcategory'] as String] : []), // 後方互換性
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
      'url': url,
      'name': name,
      'category': category,
      'subcategory_tags': subcategoryTags,
      'image_url': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? url,
    String? name,
    String? category,
    List<String>? subcategoryTags,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategoryTags: subcategoryTags ?? this.subcategoryTags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}