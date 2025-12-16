import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/yoga_group.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  // State Variables
  bool _isLoading = true;
  String _userName = "Yogi";

  // Pedometer
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  int _stepsToday = 0;
  int _stepBaseline = 0;
  String _pedestrianStatus = 'Unknown';

  // Stats
  int _streak = 0;
  int _totalClassesMonth = 0; // Up to today
  int _attendedMonth = 0;
  int _missedMonth = 0;

  @override
  void initState() {
    super.initState();
    _initPedometer();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final user = api.currentUser;
      if (user != null) {
        _userName = user.firstName;
      }

      // 1. Fetch Joined Groups
      final groups = await api.fetchMyJoinedGroups();

      // 2. Fetch Attendance for all groups
      List<AttendanceRecord> allAttendance = [];
      for (var group in groups) {
        try {
          final records = await api.getAttendanceForGroup(group.id);
          allAttendance.addAll(records);
        } catch (e) {
          debugPrint("Error fetching attendance for group ${group.id}: $e");
        }
      }

      // 3. Calculate Stats
      _calculateStats(groups, allAttendance);
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStats(
    List<YogaGroup> groups,
    List<AttendanceRecord> attendance,
  ) {
    final now = DateTime.now();
    final istNow = now.toUtc().add(const Duration(hours: 5, minutes: 30));
    final startOfMonth = DateTime(istNow.year, istNow.month, 1);

    // --- Monthly Stats ---
    int scheduledCount = 0;
    int attendedCount = 0;

    // Filter attendance for current month
    final monthAttendance = attendance.where((a) {
      final aDate = a.sessionDate.toUtc().add(
        const Duration(hours: 5, minutes: 30),
      );
      return aDate.year == istNow.year && aDate.month == istNow.month;
    }).toList();

    attendedCount = monthAttendance.length;

    // Calculate scheduled classes from Start of Month to Today (Inclusive)
    // We iterate day by day
    for (int i = 0; i <= istNow.day; i++) {
      // i=0 is startOfMonth, but we want to loop from day 1 to current day
      // Actually let's loop by adding duration
      // startOfMonth is day 1. So i=0 -> day 1. i=istNow.day-1 -> day istNow.day.
      // Wait, if today is 5th, we want 1, 2, 3, 4, 5.
      // Loop 0 to < istNow.day? No.
      // Let's use a simpler loop.
      final dateToCheck = DateTime(istNow.year, istNow.month, i);
      if (dateToCheck.day == 0) continue; // Skip 0 if loop starts at 1

      // Correct loop:
    }

    // Re-doing loop correctly
    for (int d = 1; d <= istNow.day; d++) {
      final dateToCheck = DateTime(istNow.year, istNow.month, d);

      for (var group in groups) {
        if (_isClassScheduled(group, dateToCheck)) {
          scheduledCount++;
        }
      }
    }

    // Missed can't be negative (if extra attendance recorded or logic mismatch)
    int missed = scheduledCount - attendedCount;
    if (missed < 0) missed = 0;

    // --- Streak Calculation ---
    // Logic: Look back from today.
    // If class scheduled:
    //   If attended -> streak++
    //   If not attended -> Break (Stop counting)
    // If no class scheduled -> Freeze (Continue to previous day)

    int currentStreak = 0;
    // We'll look back 365 days max for sanity
    for (int i = 0; i < 365; i++) {
      final dateToCheck = DateTime(
        istNow.year,
        istNow.month,
        istNow.day,
      ).subtract(Duration(days: i));

      // Check if ANY class was scheduled on this day across all groups
      bool wasScheduled = false;
      for (var group in groups) {
        if (_isClassScheduled(group, dateToCheck)) {
          wasScheduled = true;
          break;
        }
      }

      if (!wasScheduled) {
        // Freeze: Continue to previous day
        continue;
      }

      // Check if attended ANY class on this day
      bool attendedToday = attendance.any((a) {
        final aDate = a.sessionDate.toUtc().add(
          const Duration(hours: 5, minutes: 30),
        );
        return aDate.year == dateToCheck.year &&
            aDate.month == dateToCheck.month &&
            aDate.day == dateToCheck.day &&
            a.attendanceType == 'present';
      });

      if (attendedToday) {
        currentStreak++;
      } else {
        // Break: Scheduled but not attended
        // Exception: If it's TODAY and the class hasn't happened yet?
        // For simplicity, if it's today and not attended, we count it as break
        // UNLESS we want to be kind. But strict logic says "Break".
        // However, if I open the app at 8AM and class is at 6PM, my streak shouldn't be 0.
        // Let's handle Today specially: If Today, Scheduled, Not Attended -> Don't increment, but Don't break yet.
        if (i == 0) {
          // It's today. Just don't increment.
        } else {
          break; // Break streak for past days
        }
      }
    }

    setState(() {
      _totalClassesMonth = scheduledCount;
      _attendedMonth = attendedCount;
      _missedMonth = missed;
      _streak = currentStreak;
    });
  }

  bool _isClassScheduled(YogaGroup group, DateTime date) {
    // 1. Check Date Range
    if (date.isBefore(group.schedule.startDate) ||
        date.isAfter(group.schedule.endDate)) {
      return false;
    }

    // 2. Check Day of Week
    final dayName = DateFormat('EEEE').format(date); // "Monday", "Tuesday"...
    return group.schedule.days.contains(dayName);
  }

  // --- Pedometer Logic ---

  Future<void> _initPedometer() async {
    // Request permission
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream
          .listen(_onPedestrianStatus)
          .onError(_onPedestrianStatusError);

      // Initial check for midnight reset
      await _checkMidnightReset();
    } else {
      debugPrint("Activity Recognition permission denied");
    }
  }

  Future<void> _checkMidnightReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('pedometer_last_date');
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    ); // IST
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (lastDateStr != todayStr) {
      // It's a new day (or first run)
      // We can't reset the hardware pedometer, so we update our baseline.
      // We need the CURRENT hardware step count to set as baseline.
      // We'll do this in _onStepCount when we get the first event.
      // But here we just mark that a reset is needed or update the date.
      await prefs.setString('pedometer_last_date', todayStr);
      // We also need to reset the 'steps_today' display until we get an event
      setState(() {
        _stepsToday = 0;
      });
      // Flag to update baseline on next event
      await prefs.setBool('pedometer_needs_baseline_update', true);
    } else {
      // Same day, load baseline
      _stepBaseline = prefs.getInt('pedometer_baseline') ?? 0;
    }
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    bool needsUpdate =
        prefs.getBool('pedometer_needs_baseline_update') ?? false;

    if (needsUpdate) {
      // This is the first event of a new day. Set baseline to current total.
      _stepBaseline = event.steps;
      await prefs.setInt('pedometer_baseline', _stepBaseline);
      await prefs.setBool('pedometer_needs_baseline_update', false);
    }

    // Check if baseline is somehow larger than current (reboot?)
    if (event.steps < _stepBaseline) {
      _stepBaseline = 0;
      await prefs.setInt('pedometer_baseline', 0);
    }

    if (mounted) {
      setState(() {
        _stepsToday = event.steps - _stepBaseline;
      });
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    if (mounted) {
      setState(() {
        _pedestrianStatus = event.status;
      });
    }
  }

  void _onStepCountError(error) {
    debugPrint('Pedometer Error: $error');
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPedometerCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStreakCard()),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNextClassCard(),
                        ), // Placeholder for balance
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Yoga Overview (This Month)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOverviewStats(),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Namaste, $_userName",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPedometerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B8E23), Color(0xFF8FBC8F)], // Olive to SeaGreen
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B8E23).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Steps Today",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "$_stepsToday",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _pedestrianStatus == 'walking'
                        ? Icons.directions_walk
                        : Icons.accessibility_new,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _pedestrianStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Streak",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$_streak Days",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Keep it up!",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard() {
    // This is a placeholder or could show next class info
    // For now, let's make it a "Goal" card or similar
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                "Goal",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "10k",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Daily Steps",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("Total", "$_totalClassesMonth", Colors.blue),
          _buildVerticalDivider(),
          _buildStatItem("Attended", "$_attendedMonth", Colors.green),
          _buildVerticalDivider(),
          _buildStatItem("Missed", "$_missedMonth", Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }
}
