// lib/screens/participant/my_groups_screen.dart
import 'package:intl/intl.dart';
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
                    final theme = Theme.of(context);

                    // Formatters
                    final formattedStyle =
                        toBeginningOfSentenceCase(g.yogaStyle) ?? g.yogaStyle;
                    final formattedDifficulty = toBeginningOfSentenceCase(
                          g.difficultyLevel.replaceAll('-', ' '),
                        ) ??
                        g.difficultyLevel;

                    // This helper must exist in your project
                    final nextSessionText =
                        DateHelper.getNextSessionTextFromSchedule(g.schedule);

                    // --- NEW CARD ---
                    return Card(
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), // Match padding
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: g.id),
                          ),
                        ).then((_) {
                          // This refresh on return is good practice
                          _fetchGroups(force: true);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Group Name
                              Text(
                                g.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),

                              // 2. Description (This was missing)
                              if (g.description != null &&
                                  g.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  g.description!,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const Divider(height: 24),

                              // 3. Info Rows (Location & Schedule)
                              _buildInfoRow(
                                theme,
                                g.groupType == 'online'
                                    ? Icons.videocam_outlined
                                    : Icons.location_on_outlined,
                                g.displayLocation, // From our previous fix
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                theme,
                                Icons.calendar_today_outlined,
                                g.timingText, // From your model
                              ),
                              const SizedBox(height: 8),
                              
                              // 4. Next Session
                              _buildInfoRow(
                                theme,
                                Icons.next_plan_outlined,
                                nextSessionText,
                                color: theme.colorScheme.primary, // Highlight this
                              ),
                              
                              const SizedBox(height: 16),

                              // 5. Chips (This was missing)
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: [
                                  Chip(
                                    label: Text(formattedStyle),
                                    backgroundColor: theme
                                        .colorScheme.secondaryContainer
                                        .withOpacity(0.5),
                                    labelStyle: theme.textTheme.labelMedium,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Chip(
                                    label: Text(formattedDifficulty),
                                    backgroundColor: theme
                                        .colorScheme.tertiaryContainer
                                        .withOpacity(0.5),
                                    labelStyle: theme.textTheme.labelMedium,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
  Widget _buildInfoRow(ThemeData theme, IconData icon, String text,
      {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}