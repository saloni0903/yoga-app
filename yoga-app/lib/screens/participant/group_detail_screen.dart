// ib/screens/participant/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_scanner_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  
  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<YogaGroup> _groupFuture;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  void _loadGroupDetails() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _groupFuture = apiService.getGroupById(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: FutureBuilder<YogaGroup>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Group not found.'));
          }

          final group = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadGroupDetails(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGroupInfoCard(context, group),
                const SizedBox(height: 16),
                _buildAttendanceCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupInfoCard(BuildContext context, YogaGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.location_on_outlined, group.locationText),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.access_time_outlined, group.timingText),
          ],
        ),
      ),
    );
  }


  Widget _buildAttendanceCard(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Ready for today's session?",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR to Mark Attendance'),
              onPressed: () async {
                // 1. Navigate to the scanner
                final String? qrToken = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );

                // 2. If a token was scanned, call the API
                if (qrToken != null && mounted) {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marking attendance...')),
                    );
                    
                    // Now this line works correctly
                    await apiService.markAttendanceByQr(qrToken: qrToken);
                    
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance Marked Successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadGroupDetails(); // Refresh data
                  } catch (e) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}