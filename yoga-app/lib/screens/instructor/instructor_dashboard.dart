import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../../models/session.dart';
import '../../utils/date_helper.dart';
import '../profile/profile_screen.dart';
import '../settings_screen.dart';
import 'create_group_screen.dart';
import 'group_members_screen.dart';
import 'instructor_schedule_screen.dart'; // Importing to link to full schedule
import '../qr/qr_display_screen.dart';
import 'package:yoga_app/generated/app_localizations.dart';

// Local model for Home Tab display
class HomeSessionInfo {
  final String groupName;
  final String sessionTitle;
  final String startTime;
  final String endTime;
  final String groupId;
  final Color groupColor;

  HomeSessionInfo({
    required this.groupName,
    required this.sessionTitle,
    required this.startTime,
    required this.endTime,
    required this.groupId,
    required this.groupColor,
  });
}

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
      "Schedule",
      l10n.settings,
    ];

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
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.newGroupButton),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
            )
          : null,
    );
  }

  Widget _buildPendingApprovalScreen(
    ApiService apiService,
    User currentUser,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountPending),
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
                '${l10n.status} : ${currentUser.status.toUpperCase()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
// TAB 1: INSTRUCTOR HOME TAB
// ===============================================================

class InstructorHomeTab extends StatefulWidget {
  const InstructorHomeTab({super.key});

  @override
  State<InstructorHomeTab> createState() => _InstructorHomeTabState();
}

class _InstructorHomeTabState extends State<InstructorHomeTab> {
  bool _isLoading = true;
  String _userName = "Instructor";
  List<HomeSessionInfo> _todaysSessions = [];

  // Pedometer
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  int _stepsToday = 0;
  int _stepBaseline = 0;
  String _pedestrianStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPedometer();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final user = api.currentUser;
      if (user != null) {
        _userName = user.firstName;
      }

      // 1. Fetch Instructor's Groups
      final groups = await api.getGroups(instructorId: user?.id);

      // 2. Filter for Today's Sessions
      _calculateTodaysSessions(groups);
    } catch (e) {
      debugPrint("Error fetching instructor dashboard data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateTodaysSessions(List<YogaGroup> groups) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now); // "Monday", "Tuesday"...
    final todayDate = DateTime(now.year, now.month, now.day);

    List<HomeSessionInfo> sessions = [];

    for (var group in groups) {
      // Check Date Range
      final startDate = DateTime(
        group.schedule.startDate.year,
        group.schedule.startDate.month,
        group.schedule.startDate.day,
      );
      final endDate = DateTime(
        group.schedule.endDate.year,
        group.schedule.endDate.month,
        group.schedule.endDate.day,
      );

      if (todayDate.isBefore(startDate) || todayDate.isAfter(endDate)) {
        continue;
      }

      // Check Day of Week
      if (group.schedule.days.contains(dayName)) {
        sessions.add(
          HomeSessionInfo(
            groupName: group.name,
            sessionTitle: '${group.yogaStyle} Session',
            startTime: group.schedule.startTime,
            endTime: group.schedule.endTime,
            groupId: group.id,
            groupColor: _parseColor(group.color),
          ),
        );
      }
    }

    // Sort by start time
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    setState(() {
      _todaysSessions = sessions;
    });
  }

  Color _parseColor(String hex) {
    try {
      var sanitized = hex.trim();
      if (sanitized.startsWith('#')) sanitized = sanitized.substring(1);
      if (sanitized.length == 6) sanitized = 'FF$sanitized';
      final intVal = int.parse(sanitized, radix: 16);
      return Color(intVal);
    } catch (e) {
      return Colors.blue; // Default
    }
  }

  // --- Pedometer Logic (Same as Participant) ---

  Future<void> _initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream
          .listen(_onPedestrianStatus)
          .onError(_onPedestrianStatusError);

      await _checkMidnightReset();
    } else {
      debugPrint("Activity Recognition permission denied");
    }
  }

  Future<void> _checkMidnightReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('pedometer_last_date');
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (lastDateStr != todayStr) {
      await prefs.setString('pedometer_last_date', todayStr);
      setState(() {
        _stepsToday = 0;
      });
      await prefs.setBool('pedometer_needs_baseline_update', true);
    } else {
      _stepBaseline = prefs.getInt('pedometer_baseline') ?? 0;
    }
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    bool needsUpdate =
        prefs.getBool('pedometer_needs_baseline_update') ?? false;

    if (needsUpdate) {
      _stepBaseline = event.steps;
      await prefs.setInt('pedometer_baseline', _stepBaseline);
      await prefs.setBool('pedometer_needs_baseline_update', false);
    }

    if (event.steps < _stepBaseline) {
      _stepBaseline = 0;
      await prefs.setInt('pedometer_baseline', 0);
    }

    if (mounted) {
      setState(() {
        _stepsToday = event.steps - _stepBaseline;
      });
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    if (mounted) {
      setState(() {
        _pedestrianStatus = event.status;
      });
    }
  }

  void _onStepCountError(error) {
    debugPrint('Pedometer Error: $error');
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPedometerCard(),
                    const SizedBox(height: 24),
                    Text(
                      "Today's Classes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTodaysSessionsList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Namaste, $_userName",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPedometerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B8E23), Color(0xFF8FBC8F)], // Olive to SeaGreen
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B8E23).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Steps Today",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "$_stepsToday",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _pedestrianStatus == 'walking'
                        ? Icons.directions_walk
                        : Icons.accessibility_new,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _pedestrianStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSessionsList() {
    if (_todaysSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No classes scheduled for today.",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todaysSessions.length,
      itemBuilder: (context, index) {
        return _buildSessionCard(_todaysSessions[index]);
      },
    );
  }

  Widget _buildSessionCard(HomeSessionInfo session) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored bar for group
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: session.groupColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.startTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.endTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.groupName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.sessionTitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// TAB 2: INSTRUCTOR MY GROUPS TAB (REFINED UI)
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
    _loadGroups(); // Call directly in initState
  }

  Future<void> _loadGroups() async {
    // Ensure context is available for Provider
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _groupsFuture = apiService.getGroups(
        instructorId: apiService.currentUser?.id,
      );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  l10n.noGroupsFoundInstructor,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadGroups,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
// REFINED GROUP LIST ITEM & HELPERS
// ===============================================================

class _GroupListItem extends StatelessWidget {
  final YogaGroup group;
  final VoidCallback onUpdate;

  const _GroupListItem({required this.group, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentUser = apiService.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) return const SizedBox.shrink();

    // 1. Parse Color
    Color groupColor = theme.colorScheme.primary;
    try {
      if (group.color.isNotEmpty) {
        String hex = group.color.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        groupColor = Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      // Fallback to primary
    }

    // 2. Format Data
    final formattedStyle =
        toBeginningOfSentenceCase(group.yogaStyle) ?? group.yogaStyle;
    final formattedDifficulty =
        toBeginningOfSentenceCase(group.difficultyLevel.replaceAll('-', ' ')) ??
        group.difficultyLevel;
    final nextSessionText = DateHelper.getNextSessionTextFromSchedule(
      group.schedule,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MAIN CONTENT ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      group.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    // Description
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        group.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Info Rows
                    _buildInfoRow(
                      theme,
                      group.groupType == 'online'
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      group.displayLocation,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      theme,
                      Icons.calendar_today_outlined,
                      group.timingText,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      theme,
                      Icons.next_plan_outlined,
                      nextSessionText,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(height: 12),

                    // Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _buildCompactChip(
                          formattedStyle,
                          Colors.blue.shade50,
                          Colors.blue.shade800,
                        ),
                        _buildCompactChip(
                          formattedDifficulty,
                          Colors.orange.shade50,
                          Colors.orange.shade800,
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // --- ACTION BUTTONS (Instructor Functions) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.people_outline,
                          label: "Members",
                          onTap: () => Navigator.push(
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
                        _buildActionButton(
                          icon: Icons.qr_code_2,
                          label: "QR Code",
                          onTap: () =>
                              _generateQrCode(context, apiService, currentUser),
                        ),
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: "Edit",
                          onTap: () async {
                            final bool? groupWasUpdated =
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateGroupScreen(existingGroup: group),
                                  ),
                                );
                            if (groupWasUpdated == true) {
                              onUpdate();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // --- COLOR STRIP ---
            Container(width: 8, color: groupColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? Colors.grey[800],
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.grey[800]),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
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
      final sessionQrCode = await api.qrGenerate(
        groupId: group.id,
        sessionDate: DateTime.now(),
        createdBy: user.id,
      );
      if (!context.mounted) return;
      Navigator.pop(context); // Close dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QrDisplayScreen(qrCode: sessionQrCode, groupName: group.name),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
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
