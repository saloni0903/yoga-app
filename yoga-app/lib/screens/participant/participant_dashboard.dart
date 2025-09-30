// lib/screens/participant/participant_dashboard.dart
import 'package:flutter/material.dart';
import 'package:yoga_app/screens/profile/profile_screen.dart';
import 'package:yoga_app/screens/participant/dashboard_home_tab.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import 'find_group_screen.dart';
import 'my_groups_screen.dart';
import 'my_progress_screen.dart';

class ParticipantDashboard extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const ParticipantDashboard({
    super.key,
    required this.user,
    required this.apiService,
  });

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = const [
      DashboardHomeTab(), 
      MyGroupsScreen(),
      FindGroupScreen(),
      MyProgressScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              widget.apiService.logout();
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
        NavigationDestination( // <-- New Home Destination
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'My Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Progress',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      ),
      body: pages[_index],
    );
  }
}
