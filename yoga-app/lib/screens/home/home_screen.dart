// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../participant/participant_dashboard.dart';
import '../instructor/instructor_dashboard.dart';

/// This widget is now a simple "router". It takes no parameters.
/// Its only job is to decide which dashboard to show based on the user's role.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Consumer to get the ApiService from the provider.
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final User? user = apiService.currentUser;

        // This is a safeguard. If the user data hasn't loaded yet,
        // show a loading spinner.
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Based on the user's role, return the correct dashboard.
        // The dashboards themselves are also parameter-less now.
        if (user.role == 'instructor') {
          return const InstructorDashboard();
        }
        return const ParticipantDashboard();
      },
    );
  }
}
