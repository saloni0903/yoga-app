// lib/models/attendance.dart
class AttendanceRecord {
  final String id;
  final String groupId;
  final DateTime sessionDate;
  final String attendanceType; // RENAMED from 'type'
  final bool locationVerified;

  AttendanceRecord({
    required this.id,
    required this.groupId,
    required this.sessionDate,
    required this.attendanceType, // RENAMED from 'type'
    required this.locationVerified,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    String getGroupId(dynamic groupField) {
      if (groupField is Map<String, dynamic>) {
        return groupField['_id']?.toString() ?? '';
      }
      return groupField?.toString() ?? '';
    }

    return AttendanceRecord(
      id: j['_id'] ?? '',
      groupId: getGroupId(j['group_id']),
      sessionDate: DateTime.parse(j['session_date']),
      // The JSON key is 'attendance_type', which is correct.
      // Now it correctly assigns to our 'attendanceType' field.
      attendanceType: j['attendance_type'] ?? 'present',
      locationVerified: j['location_verified'] ?? false,
    );
  }
}

// // lib/models/attendance.dart
// class AttendanceRecord {
//   final String id;
//   final String groupId;
//   final DateTime sessionDate;
//   final String type; // present/late/...
//   final bool locationVerified;

//   AttendanceRecord({
//     required this.id,
//     required this.groupId,
//     required this.sessionDate,
//     required this.type,
//     required this.locationVerified,
//   });

//   factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
//     // Helper function to safely get the ID from a populated object or a plain string
//     String getGroupId(dynamic groupField) {
//       if (groupField is Map<String, dynamic>) {
//         return groupField['_id']?.toString() ?? '';
//       }
//       return groupField?.toString() ?? '';
//     }

//     return AttendanceRecord(
//       id: j['_id'] ?? '',
//       groupId: getGroupId(j['group_id']), // FIX: Use the helper function
//       sessionDate: DateTime.parse(j['session_date']),
//       type: j['attendance_type'] ?? 'present',
//       locationVerified: j['location_verified'] ?? false,
//     );
//   }
// }
