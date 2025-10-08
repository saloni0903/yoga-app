//lib/screens/participant/my_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  late Future<List<YogaGroup>> _enrolledGroupsFuture;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _enrolledGroupsFuture = _fetchEnrolledGroups();
  }

  Future<List<YogaGroup>> _fetchEnrolledGroups() {
    return Provider.of<ApiService>(context, listen: false).getMyJoinedGroups();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final user = apiService.currentUser;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Header with greeting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}, ${user?.fullName ?? 'User'}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<YogaGroup>>(
                  future: _enrolledGroupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final todaySessions = _getSessionsForDay(_selectedDay, snapshot.data!);
                      return Text(
                        'You have ${todaySessions.length} events today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Calendar
          Expanded(
            flex: 2,
            child: _buildCalendar(context),
          ),

          // Timeline for selected day
          Expanded(
            flex: 3,
            child: _buildTimeline(context),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(fontWeight: FontWeight.bold),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          eventLoader: (day) {
            return _getEventsForDay(day);
          },
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final theme = Theme.of(context);
    
    return FutureBuilder<List<YogaGroup>>(
      future: _enrolledGroupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading groups: ${snapshot.error}'),
          );
        }

        final groups = snapshot.data ?? [];
        final sessions = _getSessionsForDay(_selectedDay, groups);
        
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No sessions scheduled for ${DateFormat('MMM dd').format(_selectedDay)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                DateFormat('dd MMM').format(_selectedDay),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(context, session);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionInfo session) {
    final theme = Theme.of(context);
    final status = _getSessionStatus(session);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.startTime,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  session.endTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Session details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.groupName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.sessionTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.instructorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status icon
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    // This would be populated with actual session data
    // For now, return empty list
    return [];
  }

  List<SessionInfo> _getSessionsForDay(DateTime day, List<YogaGroup> groups) {
    final sessions = <SessionInfo>[];
    
    for (final group in groups) {
      // Check if this group has sessions on the selected day
      final dayOfWeek = DateFormat('EEEE').format(day);
      if (group.schedule.days.contains(dayOfWeek)) {
        sessions.add(SessionInfo(
          groupName: group.name,
          sessionTitle: '${group.yogaStyle.toUpperCase()} Session',
          instructorName: 'Instructor', // This would come from the group data
          startTime: group.schedule.startTime,
          endTime: group.schedule.endTime,
          groupId: group.id,
          sessionDate: day,
        ));
      }
    }
    
    // Sort by start time
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  SessionStatus _getSessionStatus(SessionInfo session) {
    final now = DateTime.now();
    final sessionDateTime = DateTime(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
      int.parse(session.startTime.split(':')[0]),
      int.parse(session.startTime.split(':')[1]),
    );
    
    if (sessionDateTime.isBefore(now)) {
      // Check if user attended this session
      return SessionStatus.attended; // This would check actual attendance
    } else {
      return SessionStatus.upcoming;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.attended:
        return Colors.green;
      case SessionStatus.missed:
        return Colors.red;
      case SessionStatus.upcoming:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.attended:
        return Icons.check_circle;
      case SessionStatus.missed:
        return Icons.cancel;
      case SessionStatus.upcoming:
        return Icons.schedule;
    }
  }
}

// Helper classes
class SessionInfo {
  final String groupName;
  final String sessionTitle;
  final String instructorName;
  final String startTime;
  final String endTime;
  final String groupId;
  final DateTime sessionDate;

  SessionInfo({
    required this.groupName,
    required this.sessionTitle,
    required this.instructorName,
    required this.startTime,
    required this.endTime,
    required this.groupId,
    required this.sessionDate,
  });
}

enum SessionStatus {
  attended,
  missed,
  upcoming,
}