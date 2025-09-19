// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'participant1@example.com';
    _passwordController.text = 'password123';
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        // Correct navigation to HomeScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.self_improvement, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text('Welcome Back', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Continue your yoga journey', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 48),

                  TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 16),
                  TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New to YES?', style: TextStyle(color: Colors.grey.shade700)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text('Register a New Account', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}