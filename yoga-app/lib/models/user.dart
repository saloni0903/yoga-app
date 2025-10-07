// lib/models/user.dart

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String location;
  final String? phone;
  final String? samagraId;
  final String? token;
  final String status;

  // ⭐ ADDITION: Added the missing profileImage field.
  final String? profileImage;

  // Stats for the dashboard
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
    this.samagraId,
    this.token,
    required this.status,
    this.profileImage, // ⭐ ADDITION
    required this.totalMinutesPracticed,
    required this.totalSessionsAttended,
    required this.currentStreak,
  });

  factory User.fromMemberJson(Map<String, dynamic> json) {
    final userJson = json['user_id'] as Map<String, dynamic>? ?? {};
    return User(
      id: userJson['_id'] ?? '',
      firstName: userJson['firstName'] ?? '',
      lastName: userJson['lastName'] ?? '',
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 'participant',
      location: userJson['location'] ?? '',
      phone: userJson['phone'] as String?,
      samagraId: userJson['samagraId'] as String?,
      token: '', // Member lists don't include tokens
      status: userJson['status'] ?? 'approved',
      profileImage: userJson['profileImage'] as String?, // ⭐ ADDITION
      totalMinutesPracticed: 0,
      totalSessionsAttended: 0,
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
      samagraId: userJson['samagraId'] as String?,
      token: json['token'] as String?,
      status: userJson['status'] ?? 'approved',
      profileImage: userJson['profileImage'] as String?, // ⭐ ADDITION
      totalMinutesPracticed: userJson['totalMinutesPracticed'] ?? 0,
      totalSessionsAttended: userJson['totalSessionsAttended'] ?? 0,
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
      samagraId: userJson['samagraId'] as String?,
      status: userJson['status'] ?? 'approved',
      profileImage: userJson['profileImage'] as String?, // ⭐ ADDITION
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
    String? samagraId,
    String? token,
    String? status,
    String? profileImage, // ⭐ ADDITION
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
      samagraId: samagraId ?? this.samagraId,
      token: token ?? this.token,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage, // ⭐ ADDITION
      totalMinutesPracticed:
          totalMinutesPracticed ?? this.totalMinutesPracticed,
      totalSessionsAttended:
          totalSessionsAttended ?? this.totalSessionsAttended,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
