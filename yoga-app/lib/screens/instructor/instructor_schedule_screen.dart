// NAYI FILE: lib/screens/instructor/instructor_schedule_screen.dart
// import 'package.dart';
import '../../models/user.dart'; // <-- Use User model
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../../models/user.dart';

// Yeh helper class participant file se copy ki gayi hai
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

class InstructorScheduleScreen extends StatefulWidget {
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() =>
      _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  late Future<List<YogaGroup>> _groupsFuture;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentUser = Provider.of<ApiService>(context, listen: false).currentUser;
      _refreshData();
    });
  }

  Future<List<YogaGroup>> _fetchData() {
    if (_currentUser == null) {
      return Future.value([]); // Return empty list if user is null
    }
    final apiService = Provider.of<ApiService>(context, listen: false);
    // Fetch all groups created by this instructor
    return apiService.getGroups(instructorId: _currentUser!.id);
  }

  Future<void> _refreshData() async {
    setState(() {
      _groupsFuture = _fetchData();
    });
    await _groupsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FutureBuilder<List<YogaGroup>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildCalendar(context, groups),
                  _buildTimeline(context, groups),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, List<YogaGroup> groups) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            titleTextStyle: theme.textTheme.titleLarge ?? const TextStyle(),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              // Simple marker for any session
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
          // This loader finds all sessions for a given day
          eventLoader: (day) => _getSessionsForDay(day, groups),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<YogaGroup> groups) {
    final theme = Theme.of(context);
    final sessions = _getSessionsForDay(_selectedDay, groups);

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 50,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions scheduled for this day.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            DateFormat('EEEE, MMMM dd').format(_selectedDay),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: sessions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final session = sessions[index];
            // Simplified session card, no status needed
            return _buildSessionCard(context, session);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Simplified session card (no status)
  Widget _buildSessionCard(BuildContext context, SessionInfo session) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.startTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.endTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.groupName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.sessionTitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER FUNCTIONS (Copied from Participant screen) ---

  List<SessionInfo> _getSessionsForDay(DateTime day, List<YogaGroup> groups) {
    final sessions = <SessionInfo>[];
    // Use 'EEEE' to get the full day name, e.g., "Monday"
    final dayOfWeek = DateFormat('EEEE').format(day);

    for (final group in groups) {
      // Ensure schedule and days list are not null and not empty
      if (group.schedule.days.any((d) => d.toLowerCase() == dayOfWeek.toLowerCase())) {
        sessions.add(
          SessionInfo(
            groupName: group.name,
            sessionTitle: '${group.yogaStyle} Session',
            instructorName: _currentUser?.fullName ?? 'Instructor',
            startTime: group.schedule.startTime,
            endTime: group.schedule.endTime,
            groupId: group.id,
            sessionDate: day,
          ),
        );
      }
    }
    // Sort sessions by start time
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }
}