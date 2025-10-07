// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../participant/participant_dashboard.dart';
import '../instructor/instructor_dashboard.dart'; // Make sure this is imported

class HomeScreen extends StatelessWidget {
  final User user;
  final ApiService apiService;

  const HomeScreen({super.key, required this.user, required this.apiService});

  @override
  Widget build(BuildContext context) {
    // This logic is correct. It shows the correct dashboard based on the role.
    if (user.role == 'instructor') {
      return const InstructorDashboard();
    }
    
    // Participant needs user and apiService passed down.
    return ParticipantDashboard();
  }
}