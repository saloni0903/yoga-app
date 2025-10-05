import 'my_groups_screen.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import 'find_group_screen.dart';
import 'my_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/screens/settings_screen.dart';
import 'package:yoga_app/screens/profile/profile_screen.dart';
import 'package:yoga_app/screens/participant/dashboard_home_tab.dart';

// lib/screens/participant/participant_dashboard.dart

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

   final List<String> _pageTitles = const [
    'Home',
    'My Groups',
    'Discover',
    'My Progress',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DashboardHomeTab(),
      const MyGroupsScreen(),
      const FindGroupScreen(),
      const MyProgressScreen(),
      const SettingsScreen(),
    ];

    // This PopScope widget intercepts the back button press
    return PopScope(
      canPop: _index == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_index != 0) {
          setState(() {
            _index = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to the ProfileScreen directly
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (widget.user.firstName.isNotEmpty)
                      ? widget.user.firstName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // MAKE TITLE DYNAMIC
          title: Text(_pageTitles[_index]),
          actions: [
            // REPLACE LOGOUT WITH QR SCANNER
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Mark Attendance',
              onPressed: () {
                // Navigate to the QR Scanner screen
                Navigator.of(context).pushNamed('/qr-scanner');
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
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
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
        body: _index < pages.length ? pages[_index] : pages[0],
      ),
    );
  }
}
