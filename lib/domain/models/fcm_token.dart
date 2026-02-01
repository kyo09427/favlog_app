class FCMToken {
  final String id;
  final String userId;
  final String token;
  final String? deviceType; // 'android', 'ios', 'web'
  final DateTime createdAt;
  final DateTime updatedAt;

  FCMToken({
    required this.id,
    required this.userId,
    required this.token,
    this.deviceType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FCMToken.fromJson(Map<String, dynamic> json) {
    return FCMToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      deviceType: json['device_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'device_type': deviceType,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
