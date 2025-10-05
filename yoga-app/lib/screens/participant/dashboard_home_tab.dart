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
                    Text('Health overview', style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // This would be built with real data later
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('3654/8000', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Steps'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('2.64/8.00', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('km'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('104/320', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('kcal'),
                          ],
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
              clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple effect is contained
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const StreakDialog();
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily step streak', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Track your streak and celebrate your progress',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.shield, color: Colors.purple.shade300),
                          const SizedBox(width: 8),
                          const Text('Current: 3x', style: TextStyle(fontWeight: FontWeight.bold)),
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
}