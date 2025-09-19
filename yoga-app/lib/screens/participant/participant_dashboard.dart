// lib/screens/participant/participant_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import 'find_group_screen.dart';

class ParticipantDashboard extends StatefulWidget {
  final User user;
  // FIX: Accept the authenticated ApiService instance
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
    final pages = [
      // FIX: Pass the provided apiService instance down to child screens
      const Center(child: Text("My Groups (Coming Soon)")), // Placeholder for MyGroupsScreen
      FindGroupScreen(apiService: widget.apiService),
      const Center(child: Text("Profile (Coming Soon)")),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Participant Dashboard')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'My Groups'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      body: pages[_index],
    );
  }
}