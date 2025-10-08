// lib/screens/instructor/instructor_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../profile/profile_screen.dart';
import '../settings_screen.dart';
import 'create_group_screen.dart';
import 'group_members_screen.dart';
import '../qr/qr_display_screen.dart';
import 'package:yoga_app/generated/app_localizations.dart';
import '../../utils/date_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    InstructorHomeTab(),     // Our new, dedicated dashboard tab
    InstructorMyGroupsTab(), // The logic for showing groups is now here
    SettingsScreen(),        // Re-using the existing settings screen
  ];
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final currentUser = apiService.currentUser;
    final l10n = AppLocalizations.of(context)!;

    final List<String> pageTitles = [l10n.dashboard, l10n.myGroups, l10n.settings];



    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    if (currentUser.status != 'approved') {
      return _buildPendingApprovalScreen(apiService, currentUser, l10n);
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (currentUser.firstName.isNotEmpty) ? currentUser.firstName[0].toUpperCase() : 'I',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        title: Text(pageTitles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: l10n.myGroups,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 // Only show FAB on "My Groups" tab
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.newGroupButton),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                // Note: The MyGroupsTab will need to be refreshed after a group is created.
                // A simple way is to use a callback or a state management solution.
                // For now, the user can pull-to-refresh.
              },
            )
          : null,
    );
  }

  Widget _buildPendingApprovalScreen(ApiService apiService, User currentUser, AppLocalizations l10n) {
    // This UI remains the same
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountPending),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              apiService.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 60, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              Text(
                '${l10n.status} : ${currentUser.status.toUpperCase()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n.accountPending}',
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

// ===============================================================
// NEW DEDICATED WIDGETS FOR EACH INSTRUCTOR TAB
// ===============================================================

// NEW WIDGET: A dedicated home tab for the instructor, with its own state.
class InstructorHomeTab extends StatefulWidget {
  const InstructorHomeTab({super.key});

  @override
  State<InstructorHomeTab> createState() => _InstructorHomeTabState();
}

class _InstructorHomeTabState extends State<InstructorHomeTab> {
  StreamSubscription<StepCount>? _stepCountStream;
  String _steps = '...';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (mounted) setState(() => _steps = event.steps.toString());
        },
        onError: (error) {
          if (mounted) setState(() => _steps = 'Sensor Error');
        },
        cancelOnError: true,
      );
    } else {
      if (mounted) setState(() => _steps = 'Permission Denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Welcome, Instructor!', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(Icons.directions_walk, color: Theme.of(context).colorScheme.primary),
            title: Text('Your Steps Today', style: Theme.of(context).textTheme.titleLarge),
            trailing: Text(_steps, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            title: Text('Upcoming Sessions', style: Theme.of(context).textTheme.titleLarge),
            subtitle: const Text('Your next group schedule will be shown here'),
          ),
        ),
      ],
    );
  }
}

// NEW WIDGET: The "My Groups" logic is now in its own StatefulWidget.
class InstructorMyGroupsTab extends StatefulWidget {
  const InstructorMyGroupsTab({super.key});

  @override
  State<InstructorMyGroupsTab> createState() => _InstructorMyGroupsTabState();
}

class _InstructorMyGroupsTabState extends State<InstructorMyGroupsTab> {
  late Future<List<YogaGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    // Using this ensures context is available when _loadGroups is called.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _groupsFuture = apiService.getGroups(instructorId: apiService.currentUser?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          // This will now work correctly.
          return Center(child: Text(l10n.noGroupsFoundInstructor));
        }
        return RefreshIndicator(
          onRefresh: _loadGroups,
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
}
// Your existing _GroupListItem widget can be kept here or moved to its own file.
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
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${group.locationText}\n${DateHelper.getNextSessionTextFromSchedule(group.schedule)}"),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'View Participants',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupMembersScreen(groupId: group.id, groupName: group.name, apiService: apiService))),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Generate Session QR Code',
              onPressed: () => _generateQrCode(context, apiService, currentUser),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Group',
              onPressed: () async {
                final bool? groupWasUpdated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CreateGroupScreen(existingGroup: group)));
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

  Future<void> _generateQrCode(BuildContext context, ApiService api, User user) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final sessionQrCode = await api.qrGenerate(groupId: group.id, sessionDate: DateTime.now(), createdBy: user.id);
      if (!context.mounted) return;
      Navigator.pop(context); // Close the loading dialog
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(qrCode: sessionQrCode, groupName: group.name)));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate QR Code: $e'), backgroundColor: Colors.red));
    }
  }
}