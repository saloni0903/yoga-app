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

  // CORRECTED factory for login/register response
  factory User.fromAuthJson(Map<String, dynamic> json) {
    // The 'json' variable here is the "data" object from the API response
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final firstName = userJson['firstName'] ?? '';
    final lastName = userJson['lastName'] ?? '';

    return User(
      // Use '_id' from backend, not 'id'
      id: userJson['_id'] ?? '', 
      // Combine firstName and lastName
      fullName: '$firstName $lastName'.trim(), 
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      // Get token from the top level of the "data" object
      token: json['token'] ?? '', 
    );
  }
}