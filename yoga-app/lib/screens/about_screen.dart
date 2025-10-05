import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Add this package to pubspec.yaml
// lib/screens/about_screen.dart


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Yoga App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.spa, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            Text(
              'Yoga Connect',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Version: ${snapshot.data!.version}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(height: 40),
            const Text(
              'Your go-to application for discovering and joining local yoga groups. Mark your attendance, track your progress, and stay connected with your yoga community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            const Text('© 2025 Your Company Name'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}