class UserSettings {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool enableNewReviewNotifications;
  final bool enableLikeNotifications;
  final bool enableCommentNotifications;

  UserSettings({
    required this.id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.enableNewReviewNotifications = true,
    this.enableLikeNotifications = true,
    this.enableCommentNotifications = true,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      enableNewReviewNotifications:
          json['enable_new_review_notifications'] as bool? ?? true,
      enableLikeNotifications:
          json['enable_like_notifications'] as bool? ?? true,
      enableCommentNotifications:
          json['enable_comment_notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'enable_new_review_notifications': enableNewReviewNotifications,
      'enable_like_notifications': enableLikeNotifications,
      'enable_comment_notifications': enableCommentNotifications,
    };
  }

  UserSettings copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enableNewReviewNotifications,
    bool? enableLikeNotifications,
    bool? enableCommentNotifications,
  }) {
    return UserSettings(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enableNewReviewNotifications:
          enableNewReviewNotifications ?? this.enableNewReviewNotifications,
      enableLikeNotifications:
          enableLikeNotifications ?? this.enableLikeNotifications,
      enableCommentNotifications:
          enableCommentNotifications ?? this.enableCommentNotifications,
    );
  }

  factory UserSettings.empty(String userId) {
    return UserSettings(
      id: userId,
      enableNewReviewNotifications: true,
      enableLikeNotifications: true,
      enableCommentNotifications: true,
    );
  }
}
