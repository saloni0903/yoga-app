// lib/screens/home/participant_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../participant/find_group_screen.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final currentUser = snapshot.data!;

        if (currentUser.groupId == null) {
          return _buildNoGroupView(context);
        } else {
          return _buildGroupJoinedView(context);
        }
      },
    );
  }

  Widget _buildNoGroupView(BuildContext context) {
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 60, color: Colors.grey),
            const SizedBox(height: 30),
            const Text(
              "You haven't joined a group yet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindGroupScreen(user: widget.user)),
                );
                setState(() {
                  _profileFuture = _apiService.getUserProfile(widget.user.token);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Find a Yoga Group", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGroupJoinedView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding( // FIX: Removed 'const'
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("0", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      Text("Sessions attended", style: TextStyle(fontSize: 16)),
                      Text("out of 108 total sessions"),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: 0.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.green.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: const Text("Scan Session QR Code", style: TextStyle(color: Colors.white, fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16)
          ),
        )
      ],
    );
  }
}