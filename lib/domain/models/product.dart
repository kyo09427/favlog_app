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
        // 修正: 明示的にUTCとして保存
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory Product.empty() {
    return Product(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(), // 修正: UTC指定
      userId: '',
      url: null,
      name: '',
      category: null,
      subcategory: null,
      imageUrl: null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      // 修正: parseUtcを使用してUTCとして明示的にパース
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
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
      // 修正: toUtcを追加してUTCとして保存
      'created_at': createdAt.toUtc().toIso8601String(),
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