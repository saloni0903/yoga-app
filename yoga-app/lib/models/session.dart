// lib/models/session.dart

class Session {
  final String id;
  final String groupId;
  final String groupName;
  final String groupColor;
  final DateTime sessionDate;
  final String status; // 'upcoming', 'attended', 'missed'

  Session({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupColor,
    required this.sessionDate,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final groupInfo = json['group_id'] as Map<String, dynamic>? ?? {};
    
    return Session(
      id: json['_id'] ?? json['id'],
      groupId: groupInfo['_id'] ?? '',
      groupName: groupInfo['group_name'] ?? 'Unknown Group',
      groupColor: groupInfo['color'] ?? '#808080', // Default grey
      sessionDate: DateTime.parse(json['session_date']).toLocal(),
      status: json['status'] ?? 'upcoming',
    );
  }
}