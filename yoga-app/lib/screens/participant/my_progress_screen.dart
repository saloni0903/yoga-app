//lib/screens/participant/my_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  late Future<List<AttendanceRecord>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the data when the screen is first built
    _attendanceFuture = _fetchAttendance();
  }

  Future<List<AttendanceRecord>> _fetchAttendance() {
    // Use Provider to get the ApiService instance
    return Provider.of<ApiService>(context, listen: false).getAttendanceHistory();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final user = apiService.currentUser;

    return Scaffold(
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final attendanceRecords = snapshot.data ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (user != null)
                _buildProfileHeader(user, apiService),
              const SizedBox(height: 24),
              _buildCalendar(context, attendanceRecords),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user, ApiService apiService) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 12),
        Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
        Text(user.email, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // This calls the logout method from the ApiService
            apiService.logout();
            if (mounted) {
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
          child: const Text('Logout'),
        ),
        const Divider(height: 40),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, List<AttendanceRecord> records) {
    final events = {
      for (var record in records)
        // Normalize date to midnight to use as a key
        DateTime.utc(record.sessionDate.year, record.sessionDate.month, record.sessionDate.day): ['Present']
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: DateTime.now(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          // Function to load events for each day
          eventLoader: (day) {
            return events[DateTime.utc(day.year, day.month, day.day)] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
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