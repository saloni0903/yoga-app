// lib/screens/home/instructor_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';

class InstructorDashboard extends StatefulWidget {
  final User user;
  const InstructorDashboard({super.key, required this.user});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    // First, get all groups to find the one managed by this instructor
    final allGroups = await _apiService.getAllGroups(widget.user.token);
    final myGroup = allGroups.firstWhere(
      (group) => group['instructor_id']['id'] == widget.user.id,
      orElse: () => null,
    );

    if (myGroup == null) {
      // Handle case where instructor has not created a group yet
      return {'group': null, 'members': []};
    }
    
    // If we found a group, get its members
    final members = await _apiService.getGroupMembers(myGroup['id'], widget.user.token);
    return {'group': myGroup, 'members': members};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!['group'] == null) {
          return const Center(child: Text('You have not created a group yet.'));
        }

        final group = snapshot.data!['group'];
        final members = snapshot.data!['members'] as List;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTodaySessionCard(group, members.length),
            const SizedBox(height: 24),
            _buildYourGroupCard(group),
            const SizedBox(height: 24),
            _buildRegisteredParticipantsCard(members),
             const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generate Session QR Code'),
              onPressed: () {
                // TODO: Navigate to QR Code generation screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildTodaySessionCard(Map<String, dynamic> group, int participantCount) {
    return Card(
      color: Colors.orange.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Session 6:00 AM",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "September 15, 2025    60 minutes", // Using current date for example
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$participantCount participants",
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
                Text(
                  group['location_text'].split(',').first, // Show just the park name
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildYourGroupCard(Map<String, dynamic> group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Yoga Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow("Group Name", group['group_name']),
            _buildDetailRow("Location", group['location_text']),
            _buildDetailRow("Timings", group['timings_text']),
            _buildDetailRow("Participants", "${group['members_count'] ?? 0} members"),
          ],
        ),
      ),
    );
  }

   Widget _buildRegisteredParticipantsCard(List members) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Registered Participants", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (members.isEmpty)
              const Text("No participants have joined yet.")
            else
              ...members.map((member) {
              final fullName = member['fullName'] ?? 'N/A';
              final initials = fullName.isNotEmpty ? fullName.split(' ').map((e) => e[0]).take(2).join() : 'N/A';
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Text(initials, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                title: Text(fullName),
                trailing: const Text("Member", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              );
            }).toList(),
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
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}