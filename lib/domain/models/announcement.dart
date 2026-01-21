/// お知らせ情報を表すドメインモデル
class Announcement {
  final String id;
  final DateTime createdAt;
  final String title;
  final String content;
  final String category;
  final int priority;
  final DateTime publishedAt;
  final bool isRead; // ユーザーごとの既読状態

  Announcement({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.publishedAt,
    this.isRead = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'news',
      priority: json['priority'] as int? ?? 2,
      publishedAt: DateTime.parse(json['published_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'published_at': publishedAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? content,
    String? category,
    int? priority,
    DateTime? publishedAt,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      publishedAt: publishedAt ?? this.publishedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
