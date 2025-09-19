// lib/screens/instructor/instructor_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import './qr_display_screen.dart';
import './create_group_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const InstructorDashboard({
    super.key,
    required this.user,
    required this.apiService,
  });

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late Future<YogaGroup?> _myGroupFuture;

  @override
  void initState() {
    super.initState();
    _myGroupFuture = _fetchMyGroup();
  }

  Future<void> _refreshData() {
    return setState(() {
      _myGroupFuture = _fetchMyGroup();
    });
  }

  Future<YogaGroup?> _fetchMyGroup() async {
    try {
      final allGroups = await widget.apiService.getGroups();
      return allGroups.firstWhere(
        (group) => group.instructorId == widget.user.id,
      );
    } catch (e) {
      debugPrint("Could not find a group for this instructor: $e");
      return null;
    }
  }

  void _generateAndShowQrCode(YogaGroup group) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final qrCode = await widget.apiService.qrGenerate(
        groupId: group.id,
        sessionDate: DateTime.now(),
      );
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrDisplayScreen(
              qrCode: qrCode,
              groupName: group.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error generating QR: $e')));
      }
    }
  }

  void _navigateAndRefresh(YogaGroup? existingGroup) async {
    final bool? needsRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          api: widget.apiService,
          currentUser: widget.user,
          existing: existingGroup,
        ),
      ),
    );
    if (needsRefresh == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<YogaGroup?>(
        future: _myGroupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final myGroup = snapshot.data;

          if (myGroup == null) {
            return _buildNoGroupView();
          }

          return _buildGroupDetailsView(myGroup);
        },
      ),
    );
  }

  Widget _buildNoGroupView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("You haven't created a group yet.", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateAndRefresh(null),
            child: const Text("Create Your Group"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetailsView(YogaGroup group) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildYourGroupCard(group),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Generate Session QR Code'),
            onPressed: () => _generateAndShowQrCode(group),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildYourGroupCard(YogaGroup group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Yoga Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  tooltip: 'Edit Group',
                  onPressed: () => _navigateAndRefresh(group),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Group Name", group.name),
            _buildDetailRow("Location", group.locationText),
            _buildDetailRow("Timings", group.timingText),
            _buildDetailRow("Participants", "${group.memberCount ?? 0} members"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15))),
        ],
      ),
    );
  }
}