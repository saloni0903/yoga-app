// lib/models/attendance.dart
class AttendanceRecord {
  final String id;
  final String groupId;
  final DateTime sessionDate;
  final String type; // present/late/...
  final bool locationVerified;

  AttendanceRecord({
    required this.id,
    required this.groupId,
    required this.sessionDate,
    required this.type,
    required this.locationVerified,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AttendanceRecord(
      id: j['_id'] ?? '',
      groupId: j['group_id'] ?? '', // FIX
      sessionDate: DateTime.parse(j['session_date']), // FIX
      type: j['attendance_type'] ?? 'present', // FIX
      locationVerified: j['location_verified'] ?? false, // FIX
    );
  }
}
