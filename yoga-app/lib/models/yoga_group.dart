// lib/models/yoga_group.dart

class YogaGroup {
  final String id;
  final String name;
  final String location; // Short location name
  final String locationText; // Detailed location description
  final double? latitude;
  final double? longitude;
  final String timingText;
  final String yogaStyle;
  final String difficultyLevel;
  final bool isActive;
  final String? description;
  final int maxParticipants;
  final int sessionDuration;
  final double pricePerSession;
  final String currency;
  final List<String> requirements;
  final List<String> equipmentNeeded;
  final int? memberCount;
  final String instructorId;

  YogaGroup({
    required this.id,
    required this.name,
    required this.location,
    required this.locationText,
    this.latitude,
    this.longitude,
    required this.timingText,
    required this.yogaStyle,
    required this.difficultyLevel,
    required this.isActive,
    this.description,
    required this.maxParticipants,
    required this.sessionDuration,
    required this.pricePerSession,
    required this.currency,
    this.requirements = const [],
    this.equipmentNeeded = const [],
    this.memberCount,
    required this.instructorId,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    // Helper to extract instructor ID from a populated object or a direct string
    String getInstructorId(dynamic instructorField) {
      if (instructorField is Map) {
        return instructorField['_id']?.toString() ?? '';
      }
      return instructorField?.toString() ?? '';
    }

    return YogaGroup(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['group_name'] ?? '').toString(),
      location: (j['location'] ?? '').toString(),
      locationText: (j['location_text'] ?? '').toString(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      timingText: (j['timings_text'] ?? '').toString(),
      yogaStyle: (j['yoga_style'] ?? 'hatha').toString(),
      difficultyLevel: (j['difficulty_level'] ?? 'all-levels').toString(),
      isActive: (j['is_active'] ?? true) == true,
      description: j['description']?.toString(),
      maxParticipants: (j['max_participants'] ?? 20) as int,
      sessionDuration: (j['session_duration'] ?? 60) as int,
      pricePerSession: ((j['price_per_session'] ?? 0) as num).toDouble(),
      currency: (j['currency'] ?? 'USD').toString(),
      requirements: List<String>.from(j['requirements'] ?? []),
      equipmentNeeded: List<String>.from(j['equipment_needed'] ?? []),
      instructorId: getInstructorId(j['instructor_id']),
      memberCount: j['memberCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'group_name': name,
    'location': location,
    'location_text': locationText,
    'latitude': latitude,
    'longitude': longitude,
    'timings_text': timingText,
    'yoga_style': yogaStyle,
    'difficulty_level': difficultyLevel,
    'is_active': isActive,
    'description': description,
    'max_participants': maxParticipants,
    'session_duration': sessionDuration,
    'price_per_session': pricePerSession,
    'currency': currency,
    'requirements': requirements,
    'equipment_needed': equipmentNeeded,
    'instructor_id': instructorId,
  };

  // Back-compatibility getters
  String get difficulty => difficultyLevel;
  String get timings => timingText;
}
