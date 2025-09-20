// lib/screens/instructor/instructor_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_display_screen.dart';
import 'create_group_screen.dart';
import '../../models/session_qr_code.dart';

class InstructorDashboard extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const InstructorDashboard({
    super.key,
    required this.user,
    required this.apiService,
  });

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late Future<List<YogaGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    setState(() {
      _groupsFuture = widget.apiService.getGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        onPressed: () async {
          final bool? groupWasCreated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGroupScreen(
                api: widget.apiService,
                // ✅ FIX: This line passes the current user object.
                currentUser: widget.user,
              ),
            ),
          );
          if (groupWasCreated == true) {
            _loadGroups();
          }
        },
      ),
      body: FutureBuilder<List<YogaGroup>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}'),
              ),
            );
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('No groups found. Tap the + button to create one!'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding for FAB
              itemCount: groups.length,
              itemBuilder: (_, index) {
                final group = groups[index];
                return _GroupListItem(
                  group: group,
                  api: widget.apiService,
                  onUpdate: _loadGroups,
                  // ✅ FIX: This line passes the current user object to the list item.
                  currentUser: widget.user,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GroupListItem extends StatelessWidget {
  final YogaGroup group;
  final ApiService api;
  final VoidCallback onUpdate;
  final User currentUser;

  const _GroupListItem({
    required this.group,
    required this.api,
    required this.onUpdate,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${group.locationText}\n${group.timingText}"),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Generate Session QR Code',
              onPressed: () => _generateQrCode(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Group',
              onPressed: () async {
                final bool? groupWasUpdated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGroupScreen(
                      api: api,
                      existing: group,
                      // ✅ FIX: This line passes the current user when editing a group.
                      currentUser: currentUser,
                    ),
                  ),
                );
                if (groupWasUpdated == true) {
                  onUpdate();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQrCode(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final SessionQrCode qrCode = await api.qrGenerate(
        groupId: group.id,
        sessionDate: DateTime.now(),
      );
      
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrDisplayScreen(
            qrCode: qrCode,
            groupName: group.name,
            api: api,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate QR Code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}