import '../../api_service.dart';
import '../../models/user.dart';
import '../settings_screen.dart';
import 'create_group_screen.dart';
import 'group_members_screen.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile/profile_screen.dart';
import '../../models/session_qr_code.dart';

// lib/screens/instructor/instructor_dashboard.dart

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _selectedIndex = 0;
  late Future<List<YogaGroup>> _groupsFuture;

  final List<String> _pageTitles = const ['Dashboard', 'My Groups', 'Settings'];

  @override
  void initState() {
    super.initState();
    _loadGroups(); // Load groups when the widget is first created
  }

  void _loadGroups() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (apiService.currentUser?.status == 'approved') {
      setState(() {
        _groupsFuture = apiService.getGroups(
          instructorId: apiService.currentUser?.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final currentUser = apiService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    if (currentUser.status != 'approved') {
      return _buildPendingApprovalScreen(context, apiService, currentUser);
    }

    // List of the main pages for our tabs are now built by helper methods
    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildMyGroupsTab(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (currentUser.firstName.isNotEmpty)
                    ? currentUser.firstName[0].toUpperCase()
                    : 'I',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              apiService.logout();
              if (mounted) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'My Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
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
            )
          : null,
    );
  }

  // --- Embedded Helper Widgets ---

  Widget _buildDashboardTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Instructor Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This area will soon show your schedule and stats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return FutureBuilder<List<YogaGroup>>(
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
    );
  }

  Widget _buildPendingApprovalScreen(
    BuildContext context,
    ApiService apiService,
    User currentUser,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              apiService.logout();
              if (mounted) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your instructor account is awaiting approval. You will be able to create and manage groups once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupMembersScreen(
                    groupId: group.id,
                    groupName: group.name,
                    apiService: apiService,
                  ),
                ),
              ),
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
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Group',
              onPressed: () => _confirmDeleteGroup(context, apiService),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, ApiService apiService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiService.deleteGroup(group.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        onUpdate();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QrDisplayScreen(qrCode: qrCode, groupName: group.name),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate QR Code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
