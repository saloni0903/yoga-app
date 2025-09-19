// lib/screens/qr/qr_display_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../../models/session_qr_code.dart';

class QrDisplayScreen extends StatefulWidget {
  final ApiService api;
  final YogaGroup group;
  const QrDisplayScreen({super.key, required this.api, required this.group});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  SessionQrCode? _qr;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final qr = await widget.api.qrGenerate(
        groupId: widget.group.id,
        sessionDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
      );
      setState(() => _qr = qr);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deactivate() async {
    if (_qr == null) return;
    setState(() => _loading = true);
    try {
      await widget.api.qrDeactivate(_qr!.id);
      setState(
        () => _qr = SessionQrCode(
          id: _qr!.id,
          token: _qr!.token,
          groupId: _qr!.groupId,
          sessionDate: _qr!.sessionDate,
          expiresAt: _qr!.expiresAt,
          isActive: false,
          usageCount: _qr!.usageCount,
          maxUsage: _qr!.maxUsage,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to deactivate: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qr;
    return Scaffold(
      appBar: AppBar(title: Text('QR • ${widget.group.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Session date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (qr != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: QrImageView(
                          data: qr.token,
                          version: QrVersions.auto,
                          size: 260,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.circle,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Text(qr.isActive ? 'Active' : 'Inactive'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _generate,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading || qr == null ? null : _deactivate,
                    child: const Text('Deactivate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
