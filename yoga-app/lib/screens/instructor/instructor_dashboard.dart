// REPLACE YOUR ENTIRE lib/screens/instructor/instructor_dashboard.dart FILE WITH THIS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../../models/session.dart'; // For schedule
import '../profile/profile_screen.dart';
import '../settings_screen.dart';
import 'create_group_screen.dart';
import 'group_members_screen.dart';
import 'instructor_schedule_screen.dart';
import '../qr/qr_display_screen.dart';
import 'package:yoga_app/generated/app_localizations.dart';
import '../../utils/date_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    KeepAlivePage(child: InstructorHomeTab()),
    KeepAlivePage(child: InstructorMyGroupsTab()),
    KeepAlivePage(child: InstructorScheduleScreen()),
    KeepAlivePage(child: SettingsScreen()),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final currentUser = apiService.currentUser;
    final l10n = AppLocalizations.of(context)!;

    final List<String> pageTitles = [
      l10n.dashboard,
      l10n.myGroups,
      // l10n.schedule, abhi hindi ni yar
      "Schedule",
      l10n.settings
    ];

    if (currentUser == null) {
      return const Scaffold(
          body: Center(child: Text("Error: Not logged in.")));
    }

    if (currentUser.status != 'approved') {
      return _buildPendingApprovalScreen(apiService, currentUser, l10n);
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
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
        title: Text(pageTitles[_currentIndex]),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: "Schedule",
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateGroupScreen()));
              },
            )
          : null,
    );
  }

  Widget _buildPendingApprovalScreen(
      ApiService apiService, User currentUser, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountPending),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              apiService.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
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
              const Icon(Icons.hourglass_top_rounded,
                  size: 60, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              Text(
                '${l10n.status} : ${currentUser.status.toUpperCase()}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
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
// TAB 1: INSTRUCTOR HOME TAB (PEDOMETER + UPCOMING SESSIONS)
// ===============================================================

class InstructorHomeTab extends StatefulWidget {
  const InstructorHomeTab({super.key});

  @override
  State<InstructorHomeTab> createState() => _InstructorHomeTabState();
}

class _InstructorHomeTabState extends State<InstructorHomeTab> {
  late Future<PermissionStatus> _permissionStatusFuture;
  late Future<List<Session>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _permissionStatusFuture = Permission.activityRecognition.request();
    _loadSchedule();
  }

  void _loadSchedule() {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _scheduleFuture = apiService.getInstructorSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        _loadSchedule();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, Instructor!', style: textTheme.headlineSmall),
          const SizedBox(height: 24),
          _buildStepCounterCard(textTheme, theme),
          const SizedBox(height: 16),
          _buildUpcomingSessionsCard(textTheme),
        ],
      ),
    );
  }

  Widget _buildStepCounterCard(TextTheme textTheme, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.directions_walk,
                size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            FutureBuilder<PermissionStatus>(
              future: _permissionStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final status = snapshot.data;
                if (status == PermissionStatus.granted) {
                  return StreamBuilder<StepCount>(
                    stream: Pedometer.stepCountStream,
                    builder: (context, snapshot) {
                      String steps = '...';
                      if (snapshot.hasData) {
                        steps = snapshot.data!.steps.toString();
                      } else if (snapshot.hasError) {
                        steps = 'Sensor Error';
                      }
                      return _buildStepText(textTheme, theme, steps);
                    },
                  );
                } else if (status == PermissionStatus.permanentlyDenied) {
                  return _buildPermissionDeniedText(textTheme, true);
                } else {
                  return _buildPermissionDeniedText(textTheme, false);
                }
              },
            ),
          ],
        )
      ),
    );
  }

  Widget _buildStepText(TextTheme textTheme, ThemeData theme, String steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Steps Today', style: textTheme.titleLarge),
        Text(
          steps,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedText(TextTheme textTheme, bool isPermanent) {
    return Expanded(
      child: InkWell(
        onTap: isPermanent
            ? openAppSettings
            : () => setState(() {
                  _permissionStatusFuture =
                      Permission.activityRecognition.request();
                }),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permission Denied', style: textTheme.titleLarge),
                Text(
                  isPermanent ? 'Tap to open settings' : 'Tap to request again',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const Spacer(),
            Icon(isPermanent ? Icons.settings : Icons.refresh,
                color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming Sessions', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<List<Session>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final sessions = snapshot.data ?? [];
                if (sessions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('You have no upcoming sessions.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length > 5 ? 5 : sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final sessionTime = DateFormat.yMMMEd().add_jm().format(session.sessionDate);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(session.groupName),
                      subtitle: Text(sessionTime),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// TAB 2: INSTRUCTOR MY GROUPS TAB
// ===============================================================

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _groupsFuture =
          apiService.getGroups(instructorId: apiService.currentUser?.id);
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

// ===============================================================
// HELPER WIDGETS
// ===============================================================

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
        title:
            Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            "${group.displayLocation}\n${DateHelper.getNextSessionTextFromSchedule(group.schedule)}"),
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
                          apiService: apiService))),
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
                final bool? groupWasUpdated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CreateGroupScreen(existingGroup: group)));
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
      BuildContext context, ApiService api, User user) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final sessionQrCode = await api.qrGenerate(
          groupId: group.id,
          sessionDate: DateTime.now(),
          createdBy: user.id);
      if (!context.mounted) return;
      Navigator.pop(context); // Close the loading dialog
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  QrDisplayScreen(qrCode: sessionQrCode, groupName: group.name)));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate QR Code: $e'),
          backgroundColor: Colors.red));
    }
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}