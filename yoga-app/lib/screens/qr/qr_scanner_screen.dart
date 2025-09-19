// lib/screens/qr/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final Future<void> Function(String token) onScanned;
  const QrScannerScreen({super.key, required this.onScanned});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final raw = barcodes.first.rawValue ?? '';
            if (raw.isNotEmpty) {
              setState(() => _handled = true);
              try {
                await widget.onScanned(raw);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  setState(() => _handled = false);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
                }
              }
            }
          }
        },
      ),
    );
  }
}
