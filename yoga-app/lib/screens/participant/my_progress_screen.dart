// my_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/yoga_group.dart';
import '../../models/user.dart';

// Helper to capitalize strings (e.g., "attended" -> "Attended")
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  late Future<Map<String, dynamic>> _progressDataFuture;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 1. Fetch data ONCE on init
    _progressDataFuture = _fetchData();
  }

  // 2. Create a method for fetching
  Future<Map<String, dynamic>> _fetchData() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    // 3. Call your *existing* fetch function
    return _fetchProgressData(apiService);
  }

  // 4. Create a method for refreshing
  Future<void> _refreshData() async {
    // 5. Set the state to a *new* future
    setState(() {
      _progressDataFuture = _fetchData();
    });
    // 6. Await the new future to complete the refresh
    await _progressDataFuture;
  }

  Future<Map<String, dynamic>> _fetchProgressData(ApiService apiService) async {
    // Fetches real data without any mocks
    final results = await Future.wait([
      apiService.fetchMyJoinedGroups(forceRefresh: true), // This populates the cache
      apiService.getAttendanceHistory(),
    ]);
    
    // 2. Return data from the cache and the Future.wait result
    return {
      'groups': apiService.myJoinedGroups, // Get data from the cache
      'attendance': results[1] as List<AttendanceRecord>, // Get this from the results
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final groups = data['groups'] as List<YogaGroup>;
          final attendance = data['attendance'] as List<AttendanceRecord>;
          final user = Provider.of<ApiService>(context, listen: false).currentUser;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context, user, groups),
                  _buildCalendar(context, groups, attendance),
                  // ⭐ ADDITION: The new legend card is placed here.
                  _buildLegendCard(context),
                  _buildTimeline(context, groups, attendance),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ⭐ ADDITION: New widget to display the calendar legend.
  Widget _buildLegendCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(SessionStatus.attended, context),
            _buildLegendItem(SessionStatus.missed, context),
            _buildLegendItem(SessionStatus.upcoming, context),
          ],
        ),
      ),
    );
  }

  // Helper for a single item in the legend card.
  Widget _buildLegendItem(SessionStatus status, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status.name.capitalize(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ⭐ ADDITION: New widget for the status badge on session cards.
  Widget _buildStatusBadge(SessionStatus status, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.name.capitalize(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getStatusColor(status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ⭐ UPDATE: The session card now includes the status badge.
  Widget _buildSessionCard(
    BuildContext context,
    SessionInfo session,
    SessionStatus status,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
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
                    const SizedBox(height: 8),
                    // This is where the new status badge is added
                    _buildStatusBadge(status, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The rest of the code remains the same as the previous version...
  // (I've omitted it here for brevity, but it should be in your file)

  Widget _buildHeader(
    BuildContext context,
    User? user,
    List<YogaGroup> groups,
  ) {
    final theme = Theme.of(context);
    final todaySessions = _getSessionsForDay(DateTime.now(), groups);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}, ${user?.firstName ?? 'User'}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have ${todaySessions.length} sessions scheduled today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildCalendar(
    BuildContext context,
    List<YogaGroup> groups,
    List<AttendanceRecord> attendance,
  ) {
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
              final statuses = _getSessionStatusesForDay(
                day,
                groups,
                attendance,
              );
              if (statuses.isEmpty) return null;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: statuses
                    .map((status) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      );
                    })
                    .take(4)
                    .toList(),
              );
            },
          ),
          eventLoader: (day) => _getSessionsForDay(day, groups),
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<YogaGroup> groups,
    List<AttendanceRecord> attendance,
  ) {
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
            final status = _getSessionStatus(session, attendance);
            return _buildSessionCard(context, session, status);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<SessionStatus> _getSessionStatusesForDay(
    DateTime day,
    List<YogaGroup> groups,
    List<AttendanceRecord> attendance,
  ) {
    final sessions = _getSessionsForDay(day, groups);
    return sessions
        .map((session) => _getSessionStatus(session, attendance))
        .toList();
  }

  List<SessionInfo> _getSessionsForDay(DateTime day, List<YogaGroup> groups) {
    final sessions = <SessionInfo>[];
    final dayOfWeek = DateFormat('EEEE').format(day).toLowerCase();

    for (final group in groups) {
      if (group.schedule.days.any((d) => d.toLowerCase() == dayOfWeek)) {
        sessions.add(
          SessionInfo(
            groupName: group.name,
            sessionTitle: '${group.yogaStyle} Session',
            instructorName: group.instructorName ?? 'Instructor',
            startTime: group.schedule.startTime,
            endTime: group.schedule.endTime,
            groupId: group.id,
            sessionDate: day,
          ),
        );
      }
    }
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  SessionStatus _getSessionStatus(
    SessionInfo session,
    List<AttendanceRecord> attendance,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
    );

    if (sessionDay.isAfter(today)) {
      return SessionStatus.upcoming;
    }

    final attended = attendance.any(
      (record) =>
          record.groupId == session.groupId &&
          isSameDay(record.sessionDate, session.sessionDate),
    );

    if (attended) {
      return SessionStatus.attended;
    }

    if (sessionDay.isBefore(today)) {
      return SessionStatus.missed;
    }

    final sessionEndTime = DateTime(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
      int.parse(session.endTime.split(':')[0]),
      int.parse(session.endTime.split(':')[1]),
    );

    if (now.isAfter(sessionEndTime)) {
      return SessionStatus.missed;
    } else {
      return SessionStatus.upcoming;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.attended:
        return Colors.green.shade400;
      case SessionStatus.missed:
        return Colors.red.shade400;
      case SessionStatus.upcoming:
        return Colors.blue.shade400;
    }
  }
}

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

enum SessionStatus { attended, missed, upcoming }
