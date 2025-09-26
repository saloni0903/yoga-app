// lib/screens/instructor/instructor_dashboard.dart

import 'group_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import 'create_group_screen.dart';
import '../qr/qr_display_screen.dart';
import '../../models/session_qr_code.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late Future<List<YogaGroup>> _groupsFuture;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = Provider.of<ApiService>(context, listen: false);
    // This logic is correct. It only loads groups if the user is approved.
    if (apiService.currentUser?.status == 'approved') {
      _loadGroups();
    }
  }

  void _loadGroups() {
    setState(() {
      _groupsFuture = apiService.getGroups(
        instructorId: apiService.currentUser?.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final currentUser = apiService.currentUser;

        // This check correctly identifies the problem when the register screen fails to update the global state.
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: Text("Error: Not logged in.")),
          );
        }

        // This is the gate that will now work correctly for new instructors.
        if (currentUser.status != 'approved') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Pending'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => apiService.logout(),
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 60,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Status: ${currentUser.status.toUpperCase()}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your instructor account is awaiting approval from the Aayush department. You will be able to create and manage groups once your account is approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // The rest of the dashboard for approved instructors.
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Groups'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadGroups,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => apiService.logout(),
                tooltip: 'Logout',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
            onPressed: () async {
              final bool? groupWasCreated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
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
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final groups = snapshot.data ?? [];
              if (groups.isEmpty) {
                return const Center(
                  child: Text('No groups found. Tap + to create one!'),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _loadGroups(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                  itemCount: groups.length,
                  itemBuilder: (_, index) {
                    final group = groups[index];
                    return _GroupListItem(group: group, onUpdate: _loadGroups);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupListItem extends StatelessWidget {
  final YogaGroup group;
  final VoidCallback onUpdate;

  const _GroupListItem({required this.group, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = apiService.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${group.locationText}\n${group.timingText}"),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'View Participants',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupMembersScreen(
                      groupId: group.id,
                      groupName: group.name,
                      apiService: apiService,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Generate Session QR Code',
              onPressed: () =>
                  _generateQrCode(context, apiService, currentUser),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Group',
              onPressed: () async {
                final bool? groupWasUpdated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGroupScreen(existingGroup: group),
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

  Future<void> _generateQrCode(
    BuildContext context,
    ApiService api,
    User user,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final SessionQrCode qrCode = await api.qrGenerate(
        groupId: group.id,
        sessionDate: DateTime.now(),
        createdBy: user.id,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QrDisplayScreen(qrCode: qrCode, groupName: group.name),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate QR Code: ${e}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
