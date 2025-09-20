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
      id: j['_id'] ?? '',
      token: j['token'] ?? '',
      groupId: j['group_id'] ?? '', // FIX
      sessionDate: DateTime.parse(j['session_date']), // FIX
      expiresAt: DateTime.parse(j['expires_at']), // FIX
      isActive: j['is_active'] ?? true, // FIX
      usageCount: j['usage_count'] ?? 0, // FIX
      maxUsage: j['max_usage'], // FIX
    );
  }
}
