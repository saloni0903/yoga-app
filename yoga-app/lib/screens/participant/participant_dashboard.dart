// lib/screens/participant/participant_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../home/my_groups_screen.dart';
import 'find_group_screen.dart';

class ParticipantDashboard extends StatefulWidget {
  final User user;
  const ParticipantDashboard({super.key, required this.user});

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  int _index = 0;
  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = ApiService(); // assumes token already set after login
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MyGroupsScreen(api: _api),
      FindGroupScreen(apiService: _api),
      const _PlaceholderProfile(),
    ];

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'My Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
      body: pages[_index],
    );
  }
}

class _PlaceholderProfile extends StatelessWidget {
  const _PlaceholderProfile();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile (coming soon)'));
  }
}
