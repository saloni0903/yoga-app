// lib/models/user.dart

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String token;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  factory User.fromAuthJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final firstName = userJson['firstName'] ?? '';
    final lastName = userJson['lastName'] ?? '';

    return User(
      id: userJson['_id'] ?? '',
      fullName: userJson['fullName'] ?? '',
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      token: json['token'] ?? '', 
    );
  }
}