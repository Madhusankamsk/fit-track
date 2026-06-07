class User {
  final int id;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final String? bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
