// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'participant_dashboard.dart'; // We will create this
import 'instructor_dashboard.dart'; // We will create this

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navigate back to the login screen and remove all other screens
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      // Show the correct dashboard based on the user's role
      body: user.role == 'instructor'
          ? InstructorDashboard(user: user)
          : ParticipantDashboard(user: user),
    );
  }
}