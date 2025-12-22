import 'package:uuid/uuid.dart';

class AppNotification {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String type; // 'new_review', 'like', 'comment'
  final String title;
  final String body;
  final String? relatedReviewId;
  final String? relatedUserId;
  final bool isRead;
  final DateTime? readAt;

  AppNotification({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedReviewId,
    this.relatedUserId,
    this.isRead = false,
    this.readAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedReviewId: json['related_review_id'] as String?,
      relatedUserId: json['related_user_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String).toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'related_review_id': relatedReviewId,
      'related_user_id': relatedUserId,
      'is_read': isRead,
      'read_at': readAt?.toUtc().toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? relatedReviewId,
    String? relatedUserId,
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedReviewId: relatedReviewId ?? this.relatedReviewId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
