// lib/screens/home/participant_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../participant/find_group_screen.dart';
import '../participant/qr_scanner_screen.dart'; // Import the scanner screen

class ParticipantDashboard extends StatefulWidget {
  final User user;
  const ParticipantDashboard({super.key, required this.user});

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  final ApiService _apiService = ApiService();
  late Future<User> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getUserProfile(widget.user.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        final currentUser = snapshot.data!;
        if (currentUser.groupId == null) {
          return _buildNoGroupView(context);
        } else {
          return _buildGroupJoinedView(context, currentUser);
        }
      },
    );
  }

  Widget _buildNoGroupView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 24),
            const Text("You haven't joined a group yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => FindGroupScreen(user: widget.user)));
                setState(() { _profileFuture = _apiService.getUserProfile(widget.user.token); });
              },
               style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              child: const Text("Find a Yoga Group", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGroupJoinedView(BuildContext context, User currentUser) {
    return FutureBuilder<YogaGroup>(
      future: _apiService.getGroupById(currentUser.groupId!, currentUser.token),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (groupSnapshot.hasError) return Center(child: Text("Error loading group: ${groupSnapshot.error}"));
        final group = groupSnapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("YOUR YOGA GROUP", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildYourGroupCard(group),
            const SizedBox(height: 24),
            
            // THIS IS THE SCAN BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => QrScannerScreen(user: widget.user)));
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text("Scan Session QR Code", style: TextStyle(color: Colors.white, fontSize: 18)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildYourGroupCard(YogaGroup group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person_outline, "Instructor", group.instructorName),
            _buildDetailRow(Icons.location_on_outlined, "Location", group.location),
            _buildDetailRow(Icons.access_time_outlined, "Timings", group.timings),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}