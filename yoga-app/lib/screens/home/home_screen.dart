// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../participant/participant_dashboard.dart';
import '../instructor/instructor_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.role == 'instructor') {
      return InstructorDashboard(user: user);
    }
    return ParticipantDashboard(user: user);
  }
}
