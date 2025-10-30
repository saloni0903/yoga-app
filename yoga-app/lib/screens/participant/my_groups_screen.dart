// lib/screens/participant/my_groups_screen.dart
import 'package.intl/intl.dart'; 
import 'group_detail_screen.dart';
import '../../models/yoga_group.dart';
import '../../utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  // This Future is *only* for tracking the initial load and pull-to-refresh.
  // It does NOT hold the list data.
  late Future<void> _fetchGroupsFuture;

  @override
  void initState() {
    super.initState();
    // 1. Trigger the *initial* fetch. 
    // We use the correct method `fetchMyJoinedGroups`.
    _fetchGroupsFuture = _fetchGroups(force: false);
  }

  // 2. This method is now used for both initState and RefreshIndicator.
  Future<void> _fetchGroups({bool force = false}) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // We create a new Future and store it in the state.
    // This allows the FutureBuilder to track the loading/error state
    // of the *latest* refresh action.
    final future = apiService.fetchMyJoinedGroups(forceRefresh: force);
    setState(() {
      _fetchGroupsFuture = future;
    });
    return future;
  }

  @override
  Widget build(BuildContext context) {
    // 3. We use a Consumer to listen for all state updates from ApiService.
    //    This is what makes the screen rebuild when `joinGroup` is called.
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        
        // 4. We use a FutureBuilder to handle the loading/error state
        //    of the *last fetch attempt* (initial load or refresh).
        return FutureBuilder<void>(
          future: _fetchGroupsFuture,
          builder: (context, snapshot) {
            
            // 5. CRITICAL: The list data is *always* read from the
            //    ApiService, which is the single source of truth.
            final groups = apiService.myJoinedGroups;

            // Handle initial loading state
            if (snapshot.connectionState == ConnectionState.waiting && groups.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error *only* if we have no cached data to show
            if (snapshot.hasError && groups.isEmpty) {
              return Center(
                child: Text('Failed to load groups: ${snapshot.error}'),
              );
            }

            // Handle empty state
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

            // 6. Data is ready. Build the list from the service's cached data.
            //    This UI will now be perfectly in sync.
            return RefreshIndicator(
              onRefresh: () => _fetchGroups(force: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final g = groups[i];
                  final formattedStyle = toBeginningOfSentenceCase(g.yogaStyle);
                  final formattedDifficulty = toBeginningOfSentenceCase(
                    g.difficultyLevel.replaceAll('-', ' '),
                  );

                  // This helper must exist in your project for this to compile.
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
                            // Use the displayLocation getter from our previous fix
                            Text('${g.displayLocation}\n${g.timingText}'),
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
                      ).then((_) {
                        // Optional: Refresh if returning from detail screen
                        _fetchGroups(force: true);
                      }),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}