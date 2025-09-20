// lib/models/yoga_group.dart

class YogaGroup {
  final String id;
  final String name;
  final String instructorId;
  final String locationText;
  final String timingText;
  final String yogaStyle;
  final String difficulty;
  final bool isActive;
  final int? memberCount;

  YogaGroup({
    required this.id,
    required this.name,
    required this.instructorId,
    required this.locationText,
    required this.timingText,
    required this.yogaStyle,
    required this.difficulty,
    required this.isActive,
    this.memberCount,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    return YogaGroup(
      id: j['_id'] ?? '',
      name: j['group_name'] ?? '',
      instructorId: j['instructor_id'] ?? '',
      locationText: j['location_text'] ?? '',
      timingText: j['timings_text'] ?? '',
      // ... initialize other fields
      yogaStyle: j['yoga_style'] ?? 'hatha',
      difficulty: j['difficulty_level'] ?? 'all-levels',
      isActive: j['is_active'] ?? true,
      memberCount: j['memberCount'],
    );
  }
}