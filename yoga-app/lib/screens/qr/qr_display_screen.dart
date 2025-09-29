// lib/screens/qr/qr_display_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api_service.dart';
import '../../models/session_qr_code.dart';

class QrDisplayScreen extends StatelessWidget {
  final SessionQrCode qrCode;
  final String groupName;

  const QrDisplayScreen({
    super.key,
    required this.qrCode,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Ask participants to scan this code",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Center(
              child: QrImageView(
                data: qrCode.token,
                version: QrVersions.auto,
                size: 280,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Expires at: ${TimeOfDay.fromDateTime(qrCode.expiresAt).format(context)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
