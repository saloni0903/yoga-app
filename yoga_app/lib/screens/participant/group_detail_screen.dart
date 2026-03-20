// lib/screens/participant/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_service.dart';
import '../../models/attendance.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_scanner_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<(YogaGroup, List<AttendanceRecord>)> _detailsFuture;

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
          ]).then(
            (results) =>
                (results[0] as YogaGroup, results[1] as List<AttendanceRecord>),
          );
    });
  }

  // --- Actions ---

  Future<void> _launchMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps.';
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Could not open maps application.');
    }
  }

  Future<void> _launchMeetLink(String meetLink) async {
    try {
      String cleanedLink = meetLink.trim();
      if (!cleanedLink.startsWith('http://') &&
          !cleanedLink.startsWith('https://')) {
        cleanedLink = 'https://$cleanedLink';
      }
      final uri = Uri.parse(cleanedLink);

      if (!uri.hasScheme || uri.host.isEmpty) throw 'Invalid URL format';

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No app can handle this link';
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Could not open link: ${e.toString()}');
    }
  }

  Future<void> _scanQrAndMarkAttendance(ApiService apiService) async {
    final String? qrToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (qrToken != null && mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing attendance...')),
        );
        await apiService.markAttendanceByQr(qrToken: qrToken);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance Marked Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDetails(); // Refresh history
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showErrorSnackBar(
            'Scan Failed: ${e.toString().replaceAll("Exception: ", "")}',
          );
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Light background for better card contrast
      appBar: AppBar(
        title: const Text('Group Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<(YogaGroup, List<AttendanceRecord>)>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load details.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Group not found.'));
          }

          final group = snapshot.data!.$1;
          final attendanceHistory = snapshot.data!.$2;

          return RefreshIndicator(
            onRefresh: () async => _loadDetails(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header (Name & Tags)
                  _buildHeaderSection(context, group),
                  const SizedBox(height: 20),

                  // 2. Primary Action Card (Join / Scan)
                  _buildActionCard(context, group),
                  const SizedBox(height: 16),

                  // 3. Description Section (Isolated)
                  _buildDescriptionCard(context, group),
                  const SizedBox(height: 16),

                  // 4. Location OR Platform Section (Segregated)
                  _buildLocationOrPlatformCard(context, group),
                  const SizedBox(height: 16),

                  // 5. Logistics & Essentials
                  _buildEssentialsCard(context, group),
                  const SizedBox(height: 16),

                  // 6. Instructor
                  if (group.instructorName?.isNotEmpty == true)
                    _buildInstructorCard(context, group),
                  const SizedBox(height: 16),

                  // 7. Attendance History
                  _buildAttendanceHistoryCard(context, attendanceHistory),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Component Widgets ---

  Widget _buildHeaderSection(BuildContext context, YogaGroup group) {
    final isOnline = group.groupType == 'online';
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          group.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildChip(
              label: isOnline ? 'Online' : 'Offline',
              color: isOnline ? Colors.blue.shade100 : Colors.orange.shade100,
              textColor: isOnline
                  ? Colors.blue.shade900
                  : Colors.orange.shade900,
              icon: isOnline ? Icons.videocam : Icons.location_on,
            ),
            _buildChip(
              label:
                  toBeginningOfSentenceCase(group.yogaStyle) ?? group.yogaStyle,
              color: Colors.purple.shade50,
              textColor: Colors.purple.shade900,
              icon: Icons.spa,
            ),
            _buildChip(
              label:
                  toBeginningOfSentenceCase(group.difficultyLevel) ?? 'General',
              color: Colors.green.shade50,
              textColor: Colors.green.shade900,
              icon: Icons.trending_up,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, YogaGroup group) {
    final isOnline = group.groupType == 'online';
    final hasLink = group.meetLink != null && group.meetLink!.isNotEmpty;
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Session Actions",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Primary Action
                if (isOnline && hasLink)
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Join Now'),
                      onPressed: () => _launchMeetLink(group.meetLink!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Mark Attendance'),
                      onPressed: () => _scanQrAndMarkAttendance(apiService),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                // Secondary Action (Scan for Online)
                if (isOnline && hasLink) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR'),
                      onPressed: () => _scanQrAndMarkAttendance(apiService),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, YogaGroup group) {
    final hasDesc = group.description != null && group.description!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "About this Group",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              hasDesc
                  ? group.description!
                  : 'No description provided by the instructor.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasDesc ? Colors.black87 : Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOrPlatformCard(BuildContext context, YogaGroup group) {
    final isOnline = group.groupType == 'online';

    if (isOnline) {
      return Card(
        color: Colors.blue.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Platform Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.meetLink != null && group.meetLink!.isNotEmpty
                    ? "Sessions are held online via video call."
                    : "Online session link will be updated by the instructor.",
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    // Offline Case
    final hasCoords = group.latitude != null && group.longitude != null;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header
          if (hasCoords)
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(group.latitude!, group.longitude!),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(group.latitude!, group.longitude!),
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () =>
                          _launchMaps(group.latitude!, group.longitude!),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Location",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  group.locationText.isNotEmpty
                      ? group.locationText
                      : "Location details not provided.",
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialsCard(BuildContext context, YogaGroup group) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Session Essentials",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.schedule,
              "Schedule",
              group.timingText,
            ),
            _buildInfoRow(
              context,
              Icons.timer_outlined,
              "Duration",
              "${group.sessionDurationInMinutes} mins",
            ),
            _buildInfoRow(
              context,
              Icons.payments_outlined,
              "Price",
              group.pricePerSession == 0
                  ? "Free"
                  : "${group.pricePerSession.toStringAsFixed(0)} ${group.currency}",
            ),
            _buildInfoRow(
              context,
              Icons.group_outlined,
              "Capacity",
              "Up to ${group.maxParticipants} people",
            ),
            if (group.requirements.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.rule,
                "Requirements",
                group.requirements.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorCard(BuildContext context, YogaGroup group) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            group.instructorName![0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(group.instructorName!),
        subtitle: group.instructorEmail != null
            ? Text(group.instructorEmail!)
            : const Text("Instructor"),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAttendanceHistoryCard(
    BuildContext context,
    List<AttendanceRecord> history,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Your Attendance History",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                "No attendance recorded yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = history[index];
                final dateStr = DateFormat.yMMMMEEEEd().format(
                  record.sessionDate,
                );
                final timeStr = DateFormat.jm().format(record.sessionDate);

                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(dateStr, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(timeStr, style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      toBeginningOfSentenceCase(record.attendanceType) ??
                          'Present',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- Helper ---

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
