// lib/models/yoga_group.dart
class YogaGroup {
  final String id;
  final String name;
  final String locationText;
  final String timingText;
  final String yogaStyle;
  final String difficulty;
  final bool isActive;
  final int? memberCount;
  final String instructorId;

  YogaGroup({
    required this.id,
    required this.name,
    required this.locationText,
    required this.timingText,
    required this.yogaStyle,
    required this.difficulty,
    required this.isActive,
    required this.instructorId,
    this.memberCount,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    // Helper to extract instructor ID from a populated object or a direct string
    String getInstructorId(dynamic instructorField) {
      if (instructorField is Map<String, dynamic>) {
        return instructorField['_id'] ?? '';
      }
      return instructorField?.toString() ?? '';
    }

    return YogaGroup(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['group_name'] ?? '',
      locationText: j['location_text'] ?? '',
      timingText: j['timings_text'] ?? '',
      yogaStyle: j['yoga_style'] ?? 'hatha',
      difficulty: j['difficulty_level'] ?? 'all-levels',
      isActive: j['is_active'] ?? true,
      instructorId: getInstructorId(j['instructor_id']),
      memberCount: j['memberCount'] is int ? j['memberCount'] : null,
    );
  }
}