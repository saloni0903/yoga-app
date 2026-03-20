// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // To navigate to AuthWrapper

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data for your onboarding pages
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/onboarding/1.png",
      "title": "Track your work and get the result",
      "subtitle": "Remember to keep track of your professional accomplishments.",
    },
    {
      "image": "assets/onboarding/2.png",
      "title": "Stay organized with team",
      "subtitle": "But understanding the contributions our colleagues make to our teams and companies.",
    },
    {
      "image": "assets/onboarding/3.png",
      "title": "Get notified when work happens",
      "subtitle": "Take control of notifications, collaborate live or on your own time.",
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // The swipeable pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _onboardingData[index],
                  );
                },
              ),
            ),

            // The bottom navigation area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button (hides on last page)
                  if (_currentPage != _onboardingData.length - 1)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('SKIP'),
                    )
                  else
                    const SizedBox(width: 60), // Placeholder for alignment

                  // Dots Indicator
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Start Button
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          _finishOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero, // Remove padding to center the icon
                      ),
                      child: Icon(
                        _currentPage == _onboardingData.length - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A helper widget for the content of each page
class OnboardingPage extends StatelessWidget {
  final Map<String, String> data;
  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(data['image']!),
          ),
          const SizedBox(height: 48),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            data['subtitle']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}