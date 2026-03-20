// Instructor schedule screen with group-colored calendar markers
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../../models/user.dart';

class SessionInfo {
  final String groupName;
  final String sessionTitle;
  final String instructorName;
  final String startTime;
  final String endTime;
  final String groupId;
  final DateTime sessionDate;
  final Color groupColor;

  SessionInfo({
    required this.groupName,
    required this.sessionTitle,
    required this.instructorName,
    required this.startTime,
    required this.endTime,
    required this.groupId,
    required this.sessionDate,
    required this.groupColor,
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
    // Ensure context available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentUser = Provider.of<ApiService>(
        context,
        listen: false,
      ).currentUser;
      setState(() {
        _groupsFuture = _fetchData();
      });
    });
  }

  Future<List<YogaGroup>> _fetchData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (_currentUser == null) return [];
    // Fetch groups created by this instructor
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

          final user = Provider.of<ApiService>(
            context,
            listen: false,
          ).currentUser;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context, user, groups),
                  _buildCalendar(context, groups),
                  _buildLegendCard(context, groups),
                  _buildTimeline(context, groups),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
            theme.colorScheme.primaryContainer.withOpacity(0.85),
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
                'Good ${_getGreeting()}, ${user?.firstName ?? 'Instructor'}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have ${todaySessions.length} sessions scheduled today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.95),
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

  Widget _buildLegendCard(BuildContext context, List<YogaGroup> groups) {
    final theme = Theme.of(context);
    // Deduplicate groups by id and limit to first 6 for display
    final unique = <String, YogaGroup>{};
    for (final g in groups) {
      unique[g.id] = g;
    }
    final list = unique.values.take(6).toList();

    if (list.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: list
              .map(
                (g) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _parseColor(g.color, Theme.of(context)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        g.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
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
              color: theme.colorScheme.primary.withOpacity(0.28),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final sessions = _getSessionsForDay(day, groups);
              if (sessions.isEmpty) return null;
              // pick distinct colors for that day
              final colors = <Color>[];
              for (final s in sessions) {
                if (!colors.contains(s.groupColor)) colors.add(s.groupColor);
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors
                    .take(4)
                    .map(
                      (c) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
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
            return _buildSessionCard(context, session);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionInfo session) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored bar for group
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: session.groupColor,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SessionInfo> _getSessionsForDay(DateTime day, List<YogaGroup> groups) {
    final sessions = <SessionInfo>[];
    final dayOfWeek = DateFormat('EEEE').format(day).toLowerCase();

    for (final group in groups) {
      final schedule = group.schedule;
      // Ensure the day name matches and the date falls between group's start and end
      final withinDays = schedule.days.any((d) => d.toLowerCase() == dayOfWeek);
      final startDate = DateTime(
        schedule.startDate.year,
        schedule.startDate.month,
        schedule.startDate.day,
      );
      final endDate = DateTime(
        schedule.endDate.year,
        schedule.endDate.month,
        schedule.endDate.day,
      );
      final checkDay = DateTime(day.year, day.month, day.day);
      final withinRange =
          !checkDay.isBefore(startDate) && !checkDay.isAfter(endDate);

      if (withinDays && withinRange) {
        sessions.add(
          SessionInfo(
            groupName: group.name,
            sessionTitle: '${group.yogaStyle} Session',
            instructorName: group.instructorName ?? 'Instructor',
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            groupId: group.id,
            sessionDate: day,
            groupColor: _parseColor(group.color, Theme.of(context)),
          ),
        );
      }
    }

    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  Color _parseColor(String hex, ThemeData theme) {
    try {
      var sanitized = hex.trim();
      if (sanitized.startsWith('#')) sanitized = sanitized.substring(1);
      if (sanitized.length == 6) sanitized = 'FF$sanitized';
      final intVal = int.parse(sanitized, radix: 16);
      return Color(intVal);
    } catch (e) {
      return theme.colorScheme.primary;
    }
  }
}
