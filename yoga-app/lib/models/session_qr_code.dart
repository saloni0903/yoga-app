// lib/models/session_qr_code.dart
class SessionQrCode {
  final String token;
  final String qrData; // This is the string the QR code image will be made from
  final DateTime expiresAt;

  SessionQrCode({
    required this.token,
    required this.qrData,
    required this.expiresAt,
  });

  factory SessionQrCode.fromJson(Map<String, dynamic> json) {
    return SessionQrCode(
      token: json['token'],
      qrData: json['qr_data'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}