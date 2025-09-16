// lib/screens/instructor/qr_display_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      appBar: AppBar(
        title: const Text("Today's Session QR Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              groupName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Participants can scan this code to mark their attendance.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Center(
              child: QrImageView(
                data: qrCode.qrData, // Use the data from the API
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "This code will expire at: ${TimeOfDay.fromDateTime(qrCode.expiresAt).format(context)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}