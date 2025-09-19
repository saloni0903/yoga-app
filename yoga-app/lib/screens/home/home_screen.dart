// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../participant/participant_dashboard.dart';
import '../instructor/instructor_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  // FIX: Accept the authenticated ApiService instance
  final ApiService apiService; 

  const HomeScreen({
    super.key, 
    required this.user, 
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Pass the authenticated ApiService instance down to the appropriate dashboard
    if (user.role == 'instructor') {
      return InstructorDashboard(user: user, apiService: apiService);
    }
    return ParticipantDashboard(user: user, apiService: apiService);
  }
}