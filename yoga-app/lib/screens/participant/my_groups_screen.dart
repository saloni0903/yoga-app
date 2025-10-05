import '../../api_service.dart';
import 'group_detail_screen.dart';
import '../../models/yoga_group.dart';
import '../../utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import for text formatting
// lib/screens/participant/my_groups_screen.dart


class MyGroupsScreen extends StatefulWidget {
  // ✅ FIX: No longer requires any parameters.
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => MyGroupsScreenState();
}

class MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<YogaGroup>> _myGroupsFuture;

  @override
  void initState() {
    super.initState();
    loadMyGroups();
  }

  void loadMyGroups() {
    // ✅ FIX: Get the ApiService from the Provider.
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      // ✅ FIX: Call the correct method to get ONLY joined groups.
      _myGroupsFuture = apiService.getMyJoinedGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is now managed by the parent ParticipantDashboard.
      body: FutureBuilder<List<YogaGroup>>(
        future: _myGroupsFuture,
        builder: (context, snapshot) {
          // 1. Loading State management
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load groups: ${snapshot.error}'),
            );
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "You haven't joined any groups yet.\nGo to the Discover tab to find one!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => loadMyGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                final formattedStyle = toBeginningOfSentenceCase(g.yogaStyle);
                final formattedDifficulty = toBeginningOfSentenceCase(
                  g.difficultyLevel.replaceAll('-', ' '),
                );

                final nextSessionText = DateHelper.getNextSessionText(g.timingText);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      g.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${g.locationText}\n$formattedStyle • $formattedDifficulty'),
                          const SizedBox(height: 6),
                          Text(
                            nextSessionText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: g.id),
                      ),
                    ),
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
