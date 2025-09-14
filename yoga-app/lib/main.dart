// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YES Yoga App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Set the initial route for the app
      initialRoute: '/login',
      // Define all the routes for your application
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // We define '/home' here, but we will navigate to it manually
        // from the login screen so we can pass data to it.
        // This is just to have the route name available.
        '/home': (context) => const HomeScreen(user: {}), 
      },
    );
  }
}