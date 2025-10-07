import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_scanner_screen.dart';
import 'package:intl/intl.dart';

class _SessionStatus {
  final DateTime sessionDate;
  final String status; // e.g., 'present', 'missed', etc.

  _SessionStatus({required this.sessionDate, required this.status});
}

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<(YogaGroup, List<_SessionStatus>)> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _detailsFuture =
          Future.wait([
            apiService.getGroupById(widget.groupId),
            apiService.getAttendanceForGroup(widget.groupId),
            apiService.getGroupScheduledSessions(widget.groupId),
          ]).then((results) {
            final group = results[0] as YogaGroup;
            final attendanceHistory = results[1] as List<AttendanceRecord>;
            final scheduledSessions = results[2] as List<DateTime>;

            final attendedDates = attendanceHistory
                .map(
                  (e) => DateTime.utc(
                    e.sessionDate.year,
                    e.sessionDate.month,
                    e.sessionDate.day,
                  ),
                )
                .toSet();
            final missedSessions = scheduledSessions
                .where(
                  (date) => !attendedDates.contains(
                    DateTime.utc(date.year, date.month, date.day),
                  ),
                )
                .toList();

            List<_SessionStatus> combinedSessions = [];
            for (var att in attendanceHistory) {
              combinedSessions.add(
                _SessionStatus(
                  sessionDate: att.sessionDate,
                  status: att.attendanceType,
                ),
              );
            }
            for (var miss in missedSessions) {
              combinedSessions.add(
                _SessionStatus(sessionDate: miss, status: 'missed'),
              );
            }
            combinedSessions.sort(
              (a, b) => b.sessionDate.compareTo(a.sessionDate),
            );

            return (group, combinedSessions);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<(YogaGroup, List<_SessionStatus>)>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.$1.name);
            }
            return const Text('Group Details');
          },
        ),
      ),
      body: FutureBuilder<(YogaGroup, List<_SessionStatus>)>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Group not found.'));
          }

          final group = snapshot.data!.$1;
          final attendanceHistory = snapshot.data!.$2;

          return RefreshIndicator(
            onRefresh: () async => _loadDetails(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildAttendanceCard(context),
                const SizedBox(height: 20),
                _buildAboutCard(context, group),
                const SizedBox(height: 16),
                _buildScheduleAndStyleCard(context, group),
                const SizedBox(height: 16),
                _buildLogisticsCard(context, group),
                const SizedBox(height: 16),
                if (group.instructorName != null &&
                    group.instructorName!.isNotEmpty)
                  _buildInstructorCard(context, group),
                const SizedBox(height: 16),
                _buildAttendanceHistoryCard(context, attendanceHistory),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (all widget helper methods remain as in your code with _buildAttendanceHistoryCard accepting List<_SessionStatus>)

  Widget _buildAttendanceHistoryCard(
    BuildContext context,
    List<_SessionStatus> history,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Attendance History",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text("No attendance records found for this group."),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  final statusColor = record.status == 'missed'
                      ? Colors.red
                      : Colors.green;
                  final statusText = record.status == 'missed'
                      ? 'Missed'
                      : '${record.status[0].toUpperCase()}${record.status.substring(1)}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      statusColor == Colors.green
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: statusColor,
                    ),
                    title: Text(DateFormat.yMMMMd().format(record.sessionDate)),
                    subtitle: Text('Status: $statusText'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    // This widget remains the same as it was already functional.
    final apiService = Provider.of<ApiService>(context, listen: false);
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Ready for today's session?",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan to Mark Attendance'),
              onPressed: () async {
                final String? qrToken = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
                if (qrToken != null && mounted) {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marking attendance...')),
                    );
                    await apiService.markAttendanceByQr(qrToken: qrToken);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance Marked Successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadDetails();
                  } catch (e) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Scan Failed: ${e.toString().replaceFirst("Exception: ", "")}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, YogaGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "About this Group",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (group.description != null && group.description!.isNotEmpty)
              Text(
                group.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (group.description != null && group.description!.isNotEmpty)
              const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              "Location",
              group.locationText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleAndStyleCard(BuildContext context, YogaGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Class Details",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.calendar_today_outlined,
              "Schedule",
              group.timingText,
            ),
            _buildInfoRow(
              context,
              Icons.timer_outlined,
              "Duration",
              "${group.sessionDuration} minutes",
            ),
            _buildInfoRow(
              context,
              Icons.spa_outlined,
              "Yoga Style",
              toBeginningOfSentenceCase(group.yogaStyle) ?? group.yogaStyle,
            ),
            _buildInfoRow(
              context,
              Icons.trending_up,
              "Difficulty",
              toBeginningOfSentenceCase(
                    group.difficultyLevel.replaceAll('-', ' '),
                  ) ??
                  group.difficultyLevel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsCard(BuildContext context, YogaGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Logistics",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.payments_outlined,
              "Price",
              "${group.pricePerSession.toStringAsFixed(0)} ${group.currency}",
            ),
            _buildInfoRow(
              context,
              Icons.groups_outlined,
              "Class Size",
              "Up to ${group.maxParticipants} participants",
            ),
            if (group.requirements.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.checklist_outlined,
                "Requirements",
                group.requirements.join(', '),
              ),
            if (group.equipmentNeeded.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.fitness_center_outlined,
                "Equipment",
                group.equipmentNeeded.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorCard(BuildContext context, YogaGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Instructor",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.school_outlined,
              "Name",
              group.instructorName!,
            ),
            if (group.instructorEmail != null)
              _buildInfoRow(
                context,
                Icons.alternate_email_outlined,
                "Email",
                group.instructorEmail!,
              ),
          ],
        ),
      ),
    );
  }
}

/// A flexible helper widget to create a consistent row with an icon, title, and value.
Widget _buildInfoRow(
  BuildContext context,
  IconData icon,
  String title,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    ),
  );
}
