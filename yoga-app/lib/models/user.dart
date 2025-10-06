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
  // ✅ ADDED: The status field is now included.
  final String status;
  final int totalMinutesPracticed;
  final int totalSessionsAttended;
  final int currentStreak;

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
    // ✅ ADDED: To the constructor.
    required this.status,
    required this.totalMinutesPracticed,
    required this.totalSessionsAttended,
    required this.currentStreak,
  });

  factory User.fromMemberJson(Map<String, dynamic> json) {
    final userJson = json['user_id'] as Map<String, dynamic>? ?? {};
    final firstName = userJson['firstName'] ?? '';
    final lastName = userJson['lastName'] ?? '';
    final email = userJson['email'] ?? '';
    final role = userJson['role'] ?? 'participant';
    final location = userJson['location'] ?? '';
    final phone = userJson['phone'] as String?;
    final status = userJson['status'] ?? 'approved';

    return User(
      id: userJson['_id'] ?? '',
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      location: location,
      phone: phone,
      token: '', // Member lists don't include tokens
      status: status,
      totalMinutesPracticed: 0, // Default value
      totalSessionsAttended: 0, // Default value
      currentStreak: 0,
    );
  }

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
      // ✅ ADDED: Parse the status from the JSON, with a safe default.
      status: userJson['status'] ?? 'approved',
      totalMinutesPracticed: userJson['totalMinutesPracticed'] ?? 0, // Default value
      totalSessionsAttended: userJson['totalSessionsAttended'] ?? 0, // Default value
      currentStreak: userJson['currentStreak'] ?? 0,
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
      // ✅ ADDED: Parse the status from the JSON.
      status: userJson['status'] ?? 'approved',
      totalMinutesPracticed: userJson['totalMinutesPracticed'] ?? 0,
      totalSessionsAttended: userJson['totalSessionsAttended'] ?? 0,
      currentStreak: userJson['currentStreak'] ?? 0,
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
    // ✅ ADDED: To the copyWith method.
    String? status,
    int? totalMinutesPracticed,
    int? totalSessionsAttended,
    int? currentStreak,
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
      status: status ?? this.status,
      totalMinutesPracticed: totalMinutesPracticed ?? this.totalMinutesPracticed,
      totalSessionsAttended: totalSessionsAttended ?? this.totalSessionsAttended,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
