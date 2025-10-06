import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/widgets/streak_dialog.dart';

// STEP 1: Converted to a StatefulWidget to manage live data.
class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  // STEP 2: Added state variables for the step counter.
  late StreamSubscription<StepCount> _stepCountStream;
  String _steps = '0'; // Holds the latest step count from the sensor.

  @override
  void initState() {
    super.initState();
    // STEP 3: Start listening for steps as soon as the widget is created.
    initPlatformState();
  }

  @override
  void dispose() {
    // STEP 4: Stop the stream listener when the widget is removed to save resources.
    _stepCountStream.cancel();
    super.dispose();
  }

  /// STEP 5: The core logic to initialize the pedometer stream.
  void initPlatformState() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount stepCountValue) {
        if (mounted) { // Ensure the widget is still on screen before updating state.
          setState(() {
            _steps = stepCountValue.steps.toString();
          });
        }
      },
      onError: (error) {
        print('Pedometer Error: $error');
        if (mounted) {
          setState(() {
            _steps = 'N/A';
          });
        }
      },
      cancelOnError: true,
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final user = apiService.currentUser;
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Welcome Header
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

            // --- ADDED STEP COUNTER CARD ---
            _buildStepCounterCard(textTheme, theme),
            const SizedBox(height: 16),
            // --- END OF ADDED WIDGET ---

            // Your existing "Yoga overview" card
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

            // Your existing "Daily Attendance Streak" card
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
        );
      },
    );
  }

  /// A widget to build the statistics column.
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

  /// --- NEW WIDGET METHOD FOR THE STEP CARD ---
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps Today',
                  style: textTheme.titleLarge,
                ),
                Text(
                  _steps, // This now displays the live step count
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}