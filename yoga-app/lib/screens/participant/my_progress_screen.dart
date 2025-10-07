import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  late Future<List<AttendanceRecord>> _attendanceFuture;
  List<YogaGroup> _joinedGroups = [];
  YogaGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndAttendance();
  }

  Future<void> _loadGroupsAndAttendance() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    // Fetch joined groups first
    final groups = await apiService.getMyJoinedGroups();
    setState(() {
      _joinedGroups = groups;
      if (_joinedGroups.isNotEmpty) {
        _selectedGroup = _joinedGroups[0];
      }
    });

    // Fetch attendance for selected group
    await _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    if (_selectedGroup == null) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final attendanceRecords = await apiService.getAttendanceByGroup(
      _selectedGroup!.id,
    );
    setState(() {
      _attendanceFuture = Future.value(attendanceRecords);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ApiService>(context, listen: false).currentUser;
    return Scaffold(
      body: Column(
        children: [
          if (user != null) _buildProfileHeader(user),
          const SizedBox(height: 16),
          _buildGroupDropdown(),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AttendanceRecord>>(
              future: _attendanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final attendanceRecords = snapshot.data ?? [];
                return _buildCalendar(context, attendanceRecords);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
        Text(user.email, style: const TextStyle(color: Colors.grey)),
        const Divider(height: 40),
      ],
    );
  }

  Widget _buildGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<YogaGroup>(
        value: _selectedGroup,
        isExpanded: true,
        hint: const Text('Select a group'),
        items: _joinedGroups
            .map(
              (group) =>
                  DropdownMenuItem(value: group, child: Text(group.name)),
            )
            .toList(),
        onChanged: (group) async {
          if (group == null) return;
          setState(() {
            _selectedGroup = group;
            _attendanceFuture = Future.value([]);
          });
          await _fetchAttendance();
        },
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, List<AttendanceRecord> records) {
    if (_selectedGroup == null) {
      return const Center(child: Text("No group selected"));
    }

    // Build a map of attendance dates normalized to UTC midnight
    final attendanceDates = {
      for (var record in records)
        DateTime.utc(
          record.sessionDate.year,
          record.sessionDate.month,
          record.sessionDate.day,
        ),
    };

    // Configure calendar date range to group's start and end dates
    final focusedDay = DateTime.now();
    final firstDay = _selectedGroup!.schedule.startDate;
    final lastDay = _selectedGroup!.schedule.endDate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          focusedDay: focusedDay.isBefore(firstDay) ? firstDay : focusedDay,
          firstDay: firstDay,
          lastDay: lastDay,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          eventLoader: (day) {
            final date = DateTime.utc(day.year, day.month, day.day);
            if (attendanceDates.contains(date)) {
              return ['Present'];
            }
            return [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                // Mark green dot for attended
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[400],
                    ),
                    width: 8,
                    height: 8,
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
