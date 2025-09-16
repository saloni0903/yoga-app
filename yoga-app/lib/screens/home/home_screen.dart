import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'participant_dashboard.dart';
import 'instructor_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.fullName.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: user.role == 'instructor'
          ? InstructorDashboard(user: user)
          : ParticipantDashboard(user: user),
    );
  }
}