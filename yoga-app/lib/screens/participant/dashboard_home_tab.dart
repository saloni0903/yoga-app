import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/widgets/streak_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yoga_app/models/yoga_group.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  late Future<PermissionStatus> _permissionStatusFuture;
  List<YogaGroup> _joinedGroups = [];
  YogaGroup? _selectedGroup;
  late Future<List<DateTime>> _upcomingSessionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionStatusFuture = Permission.activityRecognition.request();
    _loadGroupsAndSessions();
  }

  void _loadGroupsAndSessions() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final groups = await apiService.getMyJoinedGroups();
    setState(() {
      _joinedGroups = groups;
      _selectedGroup = groups.isNotEmpty ? groups[0] : null;
      if (_selectedGroup != null) {
        _upcomingSessionsFuture = _fetchUpcomingSessionsForGroup(
          _selectedGroup!,
        );
      }
    });
  }

  Future<List<DateTime>> _fetchUpcomingSessionsForGroup(YogaGroup group) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final sessions = await apiService.getGroupScheduledSessions(group.id);
    final now = DateTime.now();
    return sessions.where((d) => d.isAfter(now)).toList()
      ..sort((a, b) => a.compareTo(b));
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour > 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final user = apiService.currentUser;
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;

        return RefreshIndicator(
          onRefresh: () async {
            await apiService.fetchDashboardData(); // implement in ApiService
            _loadGroupsAndSessions();
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                '${getGreeting()}, ${user?.firstName ?? 'User'}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready for today\'s session?',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Group Selection Dropdown
              if (_joinedGroups.isNotEmpty)
                DropdownButton<YogaGroup>(
                  value: _selectedGroup,
                  isExpanded: true,
                  onChanged: (YogaGroup? newGroup) {
                    if (newGroup == null) return;
                    setState(() {
                      _selectedGroup = newGroup;
                      _upcomingSessionsFuture = _fetchUpcomingSessionsForGroup(
                        newGroup,
                      );
                    });
                  },
                  items: _joinedGroups
                      .map(
                        (g) => DropdownMenuItem(value: g, child: Text(g.name)),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),

              _buildStepCounterCard(textTheme, theme),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yoga overview', style: textTheme.titleLarge),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            '${user?.totalMinutesPracticed ?? 0}',
                            'Minutes',
                          ),
                          _buildStatColumn(
                            '${user?.totalSessionsAttended ?? 0}',
                            'Sessions',
                          ),
                          _buildStatColumn(
                            '${user?.currentStreak ?? 0} days',
                            'Streak',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FutureBuilder<List<DateTime>>(
                future: _upcomingSessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox(); // no upcoming sessions
                  }
                  final sessions = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Sessions for ${_selectedGroup?.name ?? ''}',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ...sessions.map(
                            (sessionDate) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_selectedGroup?.locationText ?? ''),
                              subtitle: Text(
                                '${sessionDate.day}/${sessionDate.month}/${sessionDate.year} - ${_selectedGroup?.timingText ?? ''}',
                              ),
                              leading: const Icon(Icons.calendar_today),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AttendanceDialog(
                          attendanceHistory: apiService.recentAttendance,
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Attendance Streak',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Attend sessions on consecutive days to build your streak.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current streak: ${user?.currentStreak ?? 0} days',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStepCounterCard(TextTheme textTheme, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.directions_walk,
              size: 40,
              color: theme.colorScheme.primary,
            ),
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
        ),
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
                _permissionStatusFuture = Permission.activityRecognition
                    .request();
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
            Icon(
              isPermanent ? Icons.settings : Icons.refresh,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
