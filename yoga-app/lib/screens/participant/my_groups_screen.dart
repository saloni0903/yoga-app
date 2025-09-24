// In lib/screens/participant/my_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import 'group_detail_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<YogaGroup>> _myGroupsFuture;

  @override
  void initState() {
    super.initState();
    // Load the groups when the screen is first built
    _loadMyGroups();
  }

  void _loadMyGroups() {
    // Get the ApiService from Provider and call our new method
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _myGroupsFuture = apiService.getMyJoinedGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a FutureBuilder to handle the different states of our API call
      body: FutureBuilder<List<YogaGroup>>(
        future: _myGroupsFuture,
        builder: (context, snapshot) {
          // 1. Loading State management
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Error State
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          // 3. Success State
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                "You haven't joined any groups yet.\nGo to the Discover tab to find one!",
                textAlign: TextAlign.center,
              ),
            );
          }
          // 4. Display the list of groups
          return RefreshIndicator(
            onRefresh: () async => _loadMyGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  child: ListTile(
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${group.locationText}\n${group.timingText}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: group.id),
                            ),
                        );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 