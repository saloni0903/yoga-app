import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api_service.dart';
import '../../models/user.dart';

class QrScannerScreen extends StatefulWidget {
  final User user;
  const QrScannerScreen({super.key, required this.user});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final ApiService _apiService = ApiService();
  bool isScanCompleted = false;

  void _onDetect(BarcodeCapture capture) {
    if (isScanCompleted) return;
    setState(() { isScanCompleted = true; });

    final String? qrData = capture.barcodes.first.rawValue;
    if (qrData == null) {
      _showResultDialog("Error", "Could not read QR code.");
      return;
    }
    
    final String token = qrData.split('/').last;
    _markAttendance(token);
  }

  Future<void> _markAttendance(String qrToken) async {
    try {
      final message = await _apiService.scanQrAndMarkAttendance(qrToken, widget.user.token);
      _showResultDialog("Success", message, isSuccess: true);
    } catch (e) {
      _showResultDialog("Error", e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showResultDialog(String title, String content, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSuccess) Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    ).then((_) {
      if (!isSuccess) setState(() { isScanCompleted = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}