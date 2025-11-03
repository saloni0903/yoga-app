import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Show an error message if the URL can't be launched
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the manual. Please try again later.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data once to use for styling
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About YES'),
        // ⭐ FIX: Removed hardcoded colors to allow the AppBar to adapt to the theme.
      ),
      // ⭐ FIX: The layout is now scrollable and adaptive.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Ensures the content area is at least as tall as the screen,
              // which allows vertical centering on larger screens.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Spacer pushes the main content block down.
                      const Spacer(flex: 2),

                      Image.asset(
                        'assets/images/logo.png',
                        height: 200, // You can now safely use a larger logo
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'YES App',
                        textAlign: TextAlign.center,
                        // ⭐ FIX: Using theme-aware text styles.
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(Yoga Essentials and Suryanamaskara)',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'An initiative by the Ministry of Ayush to make the practice of yoga more accessible. This platform connects certified instructors with enthusiasts, fostering a community dedicated to wellness.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),

                      // Spacer pushes the footer content to the bottom.
                      const Spacer(flex: 3),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Download User Manual'),
                        onPressed: () {
                          // ❗ IMPORTANT: Replace this with the actual URL of your PDF file
                          const pdfUrl =
                              'https://docs.google.com/document/d/1svPXe2R8nSMmSGjmI1dy_1CGKGKLNw3qILFhWwC-uX0/edit?usp=sharing';
                          _launchURL(context, pdfUrl);
                        },
                      ),
                      const SizedBox(height: 24),

                      Text('In Collaboration With', style: textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/ayush_logo.jpg',
                            height: 45,
                          ),
                          const SizedBox(width: 24),
                          Image.asset('assets/images/sgsits.png', height: 45),
                        ],
                      ),
                      const Divider(height: 48),

                      Text('Developed By', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'The students of SGSITS, Indore',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text('Version 2.0.0', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
