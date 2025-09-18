// lib/screens/participant/group_detail_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../../models/attendance.dart';
import '../qr/qr_scanner_screen.dart';

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
  List<AttendanceRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await widget.api.getGroupById(widget.groupId);
      final h = await widget.api.getAttendanceByGroup(
        widget.groupId,
        page: 1,
        limit: 20,
      );
      setState(() {
        _group = g;
        _history = h;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _group;
    return Scaffold(
      appBar: AppBar(title: const Text('Group Detail')),
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
                          Text(
                            g.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${g.locationText} • ${g.yogaStyle} • ${g.difficulty}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _AttendanceRing(history: _history),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next session',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      _computeNextSession(g.timingText),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrScannerScreen(
                            onScanned: (token) async {
                              final now = DateTime.now();
                              await widget.api.qrScan(
                                tokenValue: token,
                                groupId: g.id,
                                sessionDate: DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                ),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Attendance marked'),
                                  ),
                                );
                              }
                              await _load();
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR to mark attendance'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Attendance history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._history.map(
                    (a) => Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.event_available,
                          color: a.type == 'present'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(_formatDate(a.sessionDate)),
                        subtitle: Text(
                          'Status: ${a.type}${a.locationVerified ? ' • Location verified' : ''}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _computeNextSession(String timingText) {
    // Simplified placeholder: show as-is; can parse days/times for exact upcoming
    return timingText.isNotEmpty ? timingText : 'Schedule not set';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _AttendanceRing extends StatelessWidget {
  final List<AttendanceRecord> history;
  const _AttendanceRing({required this.history});

  @override
  Widget build(BuildContext context) {
    final total = history.length;
    final present = history.where((e) => e.type == 'present').length;
    final ratio = total == 0 ? 0.0 : present / total;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 64,
          width: 64,
          child: CircularProgressIndicator(
            value: ratio,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        Text('${(ratio * 100).round()}%'),
      ],
    );
  }
}
