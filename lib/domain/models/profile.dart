class Profile {
  final String id;
  final String username;
  final String displayId;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.username,
    required this.displayId,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      displayId: json['display_id'] ?? json['username'], // Fallback for backward compatibility
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_id': displayId,
      'avatar_url': avatarUrl,
    };
  }

  Profile copyWith({
    String? id,
    String? username,
    String? displayId,
    String? avatarUrl,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayId: displayId ?? this.displayId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}