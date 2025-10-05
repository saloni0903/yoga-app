import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About YES'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Spacer to push content from the top
            const Spacer(flex: 2),

            // App Logo
            Image.asset(
              'assets/images/logo.png', // Make sure this is your correct filename
              height: 100,
            ),
            const SizedBox(height: 16),

            // App Name & Version
            const Text(
              'YES (Yoga Essentials and Suryanamaskar)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // App Description
            const Text(
              'An initiative by the Ministry of Ayush to make the practice of yoga more accessible. This platform connects certified instructors with enthusiasts, fostering a community dedicated to wellness.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black54,
              ),
            ),

            // Spacer to push the footer to the bottom
            const Spacer(flex: 3),
          
            
            // Collaboration Logos (Smaller)
            const Text(
              'In Collaboration With',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/ayush_logo.jpg', // Ensure filename is correct
                  height: 45, // Smaller logo
                ),
                const SizedBox(width: 24),
                Image.asset(
                  'assets/images/sgsits.png', // Ensure filename is correct
                  height: 45, // Smaller logo
                ),
              ],
            ),
            const Divider(height: 32),

            // "Developed By" section at the absolute bottom
            const Text(
              'Developed By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The students of SGSITS, Indore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Version 1.0.0', // Updated version
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}