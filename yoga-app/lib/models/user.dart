// lib/models/user.dart
class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String token;
  final String? groupId; // Can be null if not in a group

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
    this.groupId,
  });

  // This factory is for the login/register response
  factory User.fromAuthJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      fullName: json['user']['fullName'],
      email: json['user']['email'],
      role: json['user']['role'],
      token: json['token'],
      groupId: json['user']['group_id'], // Get groupId from login
    );
  }
  
  // This factory is for fetching the user profile
  factory User.fromProfileJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      token: '', // Profile fetch doesn't return a token
      groupId: json['group_id'],
    );
  }
}