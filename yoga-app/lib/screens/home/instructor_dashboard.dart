import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/session_qr_code.dart';
import '../instructor/qr_display_screen.dart';
import '../instructor/create_group_screen.dart';

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

  void _generateAndShowQrCode(String groupId, String groupName) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final qrCode = await _apiService.generateQrCode(groupId, widget.user.token);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => QrDisplayScreen(qrCode: qrCode, groupName: groupName)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
  
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final allGroups = await _apiService.getAllGroups(widget.user.token);
    final myGroup = allGroups.firstWhere((group) => group['instructor_id']['_id'] == widget.user.id, orElse: () => null);
    if (myGroup == null) return {'group': null, 'members': []};
    final members = await _apiService.getGroupMembers(myGroup['_id'], widget.user.token);
    return {'group': myGroup, 'members': members};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!['group'] == null) {
          // Show "Create Group" button if no group exists
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const Text("You haven't created a group yet.", style: TextStyle(fontSize: 18)),
                 const SizedBox(height: 20),
                 ElevatedButton(
                   onPressed: () async {
                     final success = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => CreateGroupScreen(user: widget.user)));
                     if (success == true) {
                       // Refresh dashboard if group was created
                       setState(() { _dashboardDataFuture = _fetchDashboardData(); });
                     }
                   },
                   child: const Text("Create Your Group"),
                 )
              ],
            ),
          );
        }
        // if (!snapshot.hasData || snapshot.data!['group'] == null) return const Center(child: Text('You have not created a group yet.'));
        final group = snapshot.data!['group'];
        final members = snapshot.data!['members'] as List;
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildYourGroupCard(group, members.length),
            const SizedBox(height: 24),
            _buildRegisteredParticipantsCard(members),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2, color: Colors.white),
              label: const Text('Generate Session QR Code', style: TextStyle(color: Colors.white)),
              onPressed: () => _generateAndShowQrCode(group['_id'], group['group_name']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )
          ],
        );
      },
    );
  }

  Widget _buildYourGroupCard(Map<String, dynamic> group, int memberCount) {
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
            _buildDetailRow("Group Name", group['group_name'] ?? 'N/A'),
            _buildDetailRow("Location", group['location_text'] ?? 'N/A'),
            _buildDetailRow("Timings", group['timings_text'] ?? 'N/A'),
            _buildDetailRow("Participants", "$memberCount members"),
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
            if (members.isEmpty) const Text("No participants have joined yet.")
            else ...members.map((member) {
              final user = member['user_id'];
              final fullName = user?['fullName'] ?? 'N/A';
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
          SizedBox(width: 100, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        ],
      ),
    );
  }
}