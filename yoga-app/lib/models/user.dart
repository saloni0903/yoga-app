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

  factory User.fromMemberJson(Map<String, dynamic> json) {
    // 1. Get the nested user object from the 'user_id' key.
    final userJson = json['user_id'] as Map<String, dynamic>? ?? {};

    // 2. Now, look for the name fields inside that nested object.
    String name = userJson['fullName'] ?? '';
    if (name.isEmpty) {
      final firstName = userJson['firstName'] ?? '';
      final lastName = userJson['lastName'] ?? '';
      name = '$firstName $lastName'.trim();
    }

    return User(
      id: userJson['_id'] ?? '',
      fullName: name.isEmpty ? 'Unknown Member' : name,
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      token: '', // Member lists don't include tokens
    );
  }


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