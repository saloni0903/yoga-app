import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/models/user.dart';
import 'package:yoga_app/screens/participant/dashboard_home_tab.dart';
import 'package:yoga_app/screens/participant/find_group_screen.dart';
import 'package:yoga_app/screens/participant/my_groups_screen.dart';
import 'package:yoga_app/screens/participant/my_progress_screen.dart';
import 'package:yoga_app/screens/profile/profile_screen.dart';
import 'package:yoga_app/screens/settings_screen.dart';
import 'package:yoga_app/generated/app_localizations.dart';

class ParticipantDashboard extends StatefulWidget {
  const ParticipantDashboard({super.key});

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    DashboardHomeTab(),
    MyGroupsScreen(),
    FindGroupScreen(),
    MyProgressScreen(),
    SettingsScreen(),
  ];

  final List<String> _pageTitles = const [
    'Home',
    'My Groups',
    'Discover',
    'My Progress',
    'Settings',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ApiService>(context, listen: false).currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (user?.firstName.isNotEmpty ?? false)
                    ? user!.firstName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        title: Text(_pageTitles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Mark Attendance',
            onPressed: () => Navigator.of(context).pushNamed('/qr-scanner'),
          ),
        ],
      ),
      // The PageView widget enables the swiping gesture
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // Wrap each screen in a KeepAlivePage to preserve its state
        children: _screens.map((screen) => KeepAlivePage(child: screen)).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
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
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}