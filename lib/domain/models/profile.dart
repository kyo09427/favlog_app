class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isAdmin;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isAdmin = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
    };
  }

  Profile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    bool? isAdmin,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}