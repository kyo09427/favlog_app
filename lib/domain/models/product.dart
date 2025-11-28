import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String? url;
  final String name;
  final String? category;
  final String? subcategory;
  final String? imageUrl;

  Product({
    String? id,
    DateTime? createdAt,
    required this.userId,
    this.url,
    required this.name,
    this.category,
    this.subcategory,
    this.imageUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Product.empty() {
    return Product(
      id: const Uuid().v4(), // Generate a new ID for empty product
      createdAt: DateTime.now(),
      userId: '', // Empty user ID
      url: null,
      name: '', // Empty name
      category: null,
      subcategory: null,
      imageUrl: null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      url: json['url'] as String?,
      name: json['name'] as String,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'url': url,
      'name': name,
      'category': category,
      'subcategory': subcategory,
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
    String? subcategory,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
