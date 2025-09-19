import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_scanner_screen.dart'; // Make sure this import is correct

class GroupDetailScreen extends StatefulWidget {
  final ApiService api;
  final String groupId;
  const GroupDetailScreen({
    super.key,
    required this.api,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  YogaGroup? _group;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final g = await widget.api.getGroupById(widget.groupId);
      setState(() => _group = g);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load group: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _group;
    return Scaffold(
      appBar: AppBar(title: Text(g?.name ?? 'Group Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : g == null
              ? const Center(child: Text('Group not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 8),
                              Text(g.locationText),
                              const SizedBox(height: 4),
                              Text(g.timingText),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR to Mark Attendance'),
                        onPressed: () async {
                          // 1. Navigate to the scanner and wait for a result (the token string)
                          final String? token = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                          );

                          // 2. If a token was returned, call the API
                          if (token != null && mounted) {
                            try {
                              await widget.api.qrScan(tokenValue: token);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attendance Marked Successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _load(); // Refresh data after marking attendance
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Scan Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
                                  backgroundColor: Colors.red,
                                ),
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

