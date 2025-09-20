// lib/models/yoga_group.dart

class YogaGroup {
  final String id;
  final String name;
  final String instructorId; // ✅ ADDED instructorId
  final String locationText;
  final String timingText;
  final String yogaStyle;
  final String difficulty;
  final bool isActive;
  final int? memberCount;

  YogaGroup({
    required this.id,
    required this.name,
    required this.instructorId, // ✅ ADDED
    required this.locationText,
    required this.timingText,
    required this.yogaStyle,
    required this.difficulty,
    required this.isActive,
    this.memberCount,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    return YogaGroup(
      // Backend sends '_id', we map it to 'id'
      id: j['_id']?.toString() ?? '',
      name: j['group_name'] ?? '',
      // ✅ Now correctly reads the instructor_id as a String
      instructorId: j['instructor_id']?.toString() ?? '',
      locationText: j['location_text'] ?? '',
      timingText: j['timings_text'] ?? '',
      yogaStyle: j['yoga_style'] ?? 'hatha',
      difficulty: j['difficulty_level'] ?? 'all-levels',
      isActive: j['is_active'] ?? true,
      memberCount: j['memberCount'],
    );
  }
}