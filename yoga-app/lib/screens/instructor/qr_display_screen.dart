// lib/screens/qr/qr_display_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/session_qr_code.dart';
import '../../api_service.dart';

class QrDisplayScreen extends StatelessWidget {
  final SessionQrCode qrCode;
  final String groupName;
  final ApiService api;

  const QrDisplayScreen({
    super.key,
    required this.qrCode,
    required this.groupName,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Session QR Code")),
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
              "Participants can scan this to mark attendance.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Center(
              child: QrImageView(
                data: qrCode.token,
                version: QrVersions.auto,
                size: 260,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Expires at: ${TimeOfDay.fromDateTime(qrCode.expiresAt).format(context)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Deactivate this QR Code'),
              onPressed: () async {
                try {
                  await api.qrDeactivate(qrCode.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR Code Deactivated')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to deactivate: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}