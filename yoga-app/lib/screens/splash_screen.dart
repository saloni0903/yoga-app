import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/screens/home/home_screen.dart';
import 'package:yoga_app/screens/auth/login_screen.dart';
// lib/screens/splash_screen.dart


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Access the ApiService from Provider
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Wait for a minimal duration to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    // After the delay, check authentication status and navigate
    if (mounted) { // Check if the widget is still in the tree
      if (apiService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              apiService: apiService,
              user: apiService.currentUser!,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png', // Path to your logo
          width: 150, // Adjust size as needed
        ),
      ),
    );
  }
}