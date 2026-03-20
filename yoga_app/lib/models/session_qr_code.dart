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
      id: j['id'] ?? '',
      token: j['token'] ?? '',
      groupId: j['groupId'] ?? '', // FIX
      sessionDate: DateTime.parse(j['sessionDate']), // FIX
      expiresAt: DateTime.parse(j['expiresAt']), // FIX
      isActive: j['isActive'] ?? true, // FIX
      usageCount: j['usageCount'] ?? 0, // FIX
      maxUsage: j['maxUsage'], // FIX
    );
  }
}


