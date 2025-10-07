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
  State<MyGroupsScreen> createState() => MyGroupsScreenState();
}

class MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<YogaGroup>> _myGroupsFuture;
  Map<String, int> attendedCounts = {};
  Map<String, int> missedCounts = {};
  Map<String, int> remainingCounts = {};

  @override
  void initState() {
    super.initState();
    _myGroupsFuture = Provider.of<ApiService>(
      context,
      listen: false,
    ).getMyJoinedGroups();
    // We will load attendance stats after groups are loaded
  }

  Future<void> loadMyGroups() async {
    setState(() {
      _myGroupsFuture = Provider.of<ApiService>(
        context,
        listen: false,
      ).getMyJoinedGroups();
    });
  }

  Future<void> loadAttendanceStats(List<YogaGroup> groups) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    for (var group in groups) {
      final sessions = await apiService.fetchGroupSessions(group.id);
      final attendance = await apiService.getAttendanceByGroup(group.id);
      final now = DateTime.now();

      final attendedDates = attendance
          .map(
            (a) => DateTime.utc(
              a.sessionDate.year,
              a.sessionDate.month,
              a.sessionDate.day,
            ),
          )
          .toSet();

      // Count attended: attendance dates before or equal to now
      final attendedCount = attendedDates
          .where((d) => d.isBefore(now) || d.isAtSameMomentAs(now))
          .length;
      // Missed: scheduled sessions before now not attended
      final missedCount = sessions
          .where(
            (d) =>
                (d.isBefore(now) || d.isAtSameMomentAs(now)) &&
                !attendedDates.contains(d),
          )
          .length;
      // Remaining: scheduled sessions after now
      final remainingCount = sessions.where((d) => d.isAfter(now)).length;

      setState(() {
        attendedCounts[group.id] = attendedCount;
        missedCounts[group.id] = missedCount;
        remainingCounts[group.id] = remainingCount;
      });
    }
  }

  void _confirmLeaveGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? Your attendance data for this group will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ApiService>(
          context,
          listen: false,
        ).leaveGroup(groupId);
        // Refresh groups and stats after leaving
        await loadMyGroups();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
      }
    }
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

          // Load attendance stats once groups are available
          loadAttendanceStats(groups);

          return RefreshIndicator(
            onRefresh: () async => loadMyGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                final attended = attendedCounts[g.id] ?? 0;
                final missed = missedCounts[g.id] ?? 0;
                final remaining = remainingCounts[g.id] ?? 0;

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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.locationText}\n${g.timingText}'),
                        const SizedBox(height: 6),
                        Text(
                          'Attended: $attended, Missed: $missed, Remaining: $remaining',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'details') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(groupId: g.id),
                            ),
                          );
                        } else if (value == 'leave') {
                          _confirmLeaveGroup(g.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Text('Group Details'),
                        ),
                        const PopupMenuItem(
                          value: 'leave',
                          child: Text('Leave Group'),
                        ),
                      ],
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
