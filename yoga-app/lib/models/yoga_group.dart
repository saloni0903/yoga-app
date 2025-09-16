// lib/models/yoga_group.dart
class YogaGroup {
  final String id;
  final String name;
  final String location;
  final String timings;
  final String instructorName;
  final int memberCount;

  YogaGroup({
    required this.id,
    required this.name,
    required this.location,
    required this.timings,
    required this.instructorName,
    required this.memberCount,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> json) {
    return YogaGroup(
      id: json['id'] ?? 'N/A',
      name: json['group_name'] ?? 'Unnamed Group',
      location: json['location_text'] ?? 'No Location',
      timings: json['timings_text'] ?? 'No Timings',
      instructorName: json['instructor_id']?['fullName'] ?? 'N/A',
      memberCount: json['memberCount'] ?? 0,
    );
  }
}