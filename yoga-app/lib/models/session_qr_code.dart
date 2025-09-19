// lib/models/session_qr_code.dart
class SessionQrCode {
  final String id;
  final String token;
  final String groupId;
  final DateTime sessionDate;
  final DateTime expiresAt;
  final bool isActive;
  final int usageCount;
  final int? maxUsage;

  SessionQrCode({
    required this.id,
    required this.token,
    required this.groupId,
    required this.sessionDate,
    required this.expiresAt,
    required this.isActive,
    required this.usageCount,
    this.maxUsage,
  });

  factory SessionQrCode.fromJson(Map<String, dynamic> j) {
    return SessionQrCode(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      token: j['token'] ?? '',
      groupId: j['groupid']?.toString() ?? '',
      sessionDate: DateTime.parse(j['sessiondate']),
      expiresAt: DateTime.parse(j['expiresat']),
      isActive: j['isactive'] ?? true,
      usageCount: (j['usagecount'] ?? 0) as int,
      maxUsage: j['maxusage'] is int ? j['maxusage'] : null,
    );
  }
}
