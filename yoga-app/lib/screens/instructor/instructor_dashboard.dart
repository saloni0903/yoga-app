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
  // FIX: Accept the authenticated ApiService instance
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
       // FIX: Use the ApiService instance provided via the widget
       _groupsFuture = widget.apiService.getGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => CreateGroupScreen(api: widget.apiService)),
          );
          if (result == true) {
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('No groups yet. Create one!'));
          }
          
          return RefreshIndicator(
            onRefresh: () async => _loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final group = groups[i];
                return _GroupListItem(
                  group: group,
                  api: widget.apiService,
                  onUpdate: _loadGroups,
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

  const _GroupListItem({required this.group, required this.api, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(group.locationText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Generate QR',
              onPressed: () => _generateQrCode(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () async {
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CreateGroupScreen(api: api, existing: group)));
                if(result == true) {
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
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final qrCode = await api.qrGenerate(groupId: group.id, sessionDate: DateTime.now());
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(api: api, qrCode: qrCode, groupName: group.name)));
    } catch(e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}