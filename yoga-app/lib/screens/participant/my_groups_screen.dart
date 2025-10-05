import 'package:intl/intl.dart'; 
import 'group_detail_screen.dart';
import '../../models/yoga_group.dart';
import '../../utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart'; // Make sure this is correctly imported
// lib/screens/participant/my_groups_screen.dart

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => MyGroupsScreenState();
}

class MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<YogaGroup>> _myGroupsFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMyGroups();
    });
  }

  void loadMyGroups() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _myGroupsFuture = apiService.getMyJoinedGroups();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<YogaGroup>>(
        future: _myGroupsFuture,
        builder: (context, snapshot) {
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

                final nextSessionText = DateHelper.getNextSessionTextFromSchedule(g.schedule);

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
                          Text('${g.locationText}\n${g.timingText}'),
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