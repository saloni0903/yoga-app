// lib/screens/participant/dashboard_home_tab.dart
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/widgets/streak_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  // ✨ We only need to store the result of the permission check now.
  late Future<PermissionStatus> _permissionStatusFuture;

  @override
  void initState() {
    super.initState();
    // ✨ Request permission once when the widget is created.
    _permissionStatusFuture = Permission.activityRecognition.request();
  }
  
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour > 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here so the dashboard only rebuilds if the user data actually changes.
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final user = apiService.currentUser;
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;

        return RefreshIndicator(
          // 🚨 Make sure you have a real implementation for this in api_service.dart
          // or remove it for now.
          onRefresh: () async { /* await apiService.fetchDashboardData(); */ },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Welcome Header (This will NOT rebuild with every step)
              Text(
                '${getGreeting()}, ${user?.firstName ?? 'User'}',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready for today\'s session?',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // ✨ Step Counter Card now handles its own state efficiently.
              _buildStepCounterCard(textTheme, theme),
              const SizedBox(height: 16),

              // Yoga Overview Card (This will NOT rebuild with every step)
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
                          _buildStatColumn('${user?.totalMinutesPracticed ?? 0}', 'Minutes'),
                          _buildStatColumn('${user?.totalSessionsAttended ?? 0}', 'Sessions'),
                          _buildStatColumn('${user?.currentStreak ?? 0} days', 'Streak'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attendance Streak Card (This will NOT rebuild with every step)
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
                        Text('Daily Attendance Streak', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Attend sessions on consecutive days to build your streak.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Current streak: ${user?.currentStreak ?? 0} days',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        )
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
  
  // A helper widget for stats
  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // ✨ This widget now perfectly manages the pedometer stream state.
  Widget _buildStepCounterCard(TextTheme textTheme, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.directions_walk, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            // We use a FutureBuilder to handle the permission request.
            FutureBuilder<PermissionStatus>(
              future: _permissionStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final status = snapshot.data;
                if (status == PermissionStatus.granted) {
                  // If permission is granted, use StreamBuilder to listen for steps.
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

  // Helper to build the step count text UI
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

  // Helper to build the permission denied UI
  Widget _buildPermissionDeniedText(TextTheme textTheme, bool isPermanent) {
    return Expanded(
      child: InkWell(
        onTap: isPermanent ? openAppSettings : () => setState(() {
          _permissionStatusFuture = Permission.activityRecognition.request();
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
            Icon(isPermanent ? Icons.settings : Icons.refresh, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}