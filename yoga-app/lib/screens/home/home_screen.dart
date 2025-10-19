// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../participant/participant_dashboard.dart';
import '../instructor/instructor_dashboard.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const HomeScreen({super.key, required this.user, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications here. This context is safe and will not cause a crash.
    FirebaseNotificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    // This logic correctly shows the dashboard based on the user's role.
    if (widget.user.role == 'instructor') {
      return const InstructorDashboard();
    }

    return const ParticipantDashboard();
  }
}