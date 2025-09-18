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

  YogaGroup({
    required this.id,
    required this.name,
    required this.locationText,
    required this.timingText,
    required this.yogaStyle,
    required this.difficulty,
    required this.isActive,
    this.memberCount,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    return YogaGroup(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['groupname'] ?? '',
      locationText: j['locationtext'] ?? '',
      timingText: j['timingstext'] ?? '',
      yogaStyle: j['yogastyle'] ?? 'hatha',
      difficulty: j['difficultylevel'] ?? 'all-levels',
      isActive: j['isactive'] ?? true,
      memberCount: j['memberCount'] is int ? j['memberCount'] : null,
    );
  }
}
