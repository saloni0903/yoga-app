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
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      groupId: j['groupid']?.toString() ?? '',
      sessionDate: DateTime.parse(j['sessiondate']),
      type: j['attendancetype'] ?? 'present',
      locationVerified: j['locationverified'] ?? false,
    );
  }
}
