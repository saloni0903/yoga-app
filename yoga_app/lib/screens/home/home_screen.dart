// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../api_service.dart';
import '../../services/notification_service.dart';
import '../../users_api_service.dart';


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
    FirebaseNotificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("API Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final api = UsersApiService();
              const token = "PASTE_YOUR_JWT_TOKEN_HERE";
              final users = await api.getUsers(token);
              print("Users from backend: $users");
            } catch (e) {
              print("API error: $e");
            }
          },
          child: const Text("Test Users API"),
        ),
      ),
    );
  }
}
