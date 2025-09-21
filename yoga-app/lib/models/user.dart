// lib/models/user.dart
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String location;
  final String? phone;
  final String? token;

  String get fullName => '$firstName $lastName'.trim();

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.location,
    this.phone,
    this.token,
  });

  factory User.fromAuthJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    return User(
      id: userJson['_id'] ?? '',
      firstName: userJson['firstName'] ?? '',
      lastName: userJson['lastName'] ?? '',
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      location: userJson['location'] ?? '',
      phone: userJson['phone'] as String?,
      token: json['token'] as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> userJson) {
    return User(
      id: userJson['_id'] ?? '',
      firstName: userJson['firstName'] ?? '',
      lastName: userJson['lastName'] ?? '',
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      location: userJson['location'] ?? '',
      phone: userJson['phone'] as String?,
    );
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? location,
    String? phone,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      token: token ?? this.token,
    );
  }
}
