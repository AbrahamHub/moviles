class User {
  final String username;
  final String email;
  final String password;

  final DateTime createdAt;
  final DateTime? updatedAt;
  User({
    required this.username,
    required this.email,
    required this.password,
    required this.createdAt,
    this.updatedAt,
  });
}