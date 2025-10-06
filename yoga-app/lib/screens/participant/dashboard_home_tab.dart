import '../../api_service.dart';
import '../../models/user.dart';      
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/widgets/streak_dialog.dart';

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

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
              'Last synced just now',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

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
                        // Assuming user object has these new fields
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

            // Daily Step Streak Card (Tappable)
            Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // SIMPLIFIED: Pass the list from the ApiService directly.
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
                          style: const TextStyle(fontWeight: FontWeight.bold)
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
      }
    );
  }
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
}