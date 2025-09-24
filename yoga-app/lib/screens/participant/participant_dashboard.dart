// lib/screens/participant/participant_dashboard.dart
import 'package:flutter/material.dart';
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
      MyGroupsScreen(),
      FindGroupScreen(),
      MyProgressScreen(), 
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Participant Dashboard')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'My Groups'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Progress'),
        ],
      ),
      body: pages[_index],
    );
  }
}