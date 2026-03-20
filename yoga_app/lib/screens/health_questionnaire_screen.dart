// lib/screens/health_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/screens/instructor/instructor_dashboard.dart';
import 'package:yoga_app/screens/participant/participant_dashboard.dart';
import '../../data/health_questions.dart';
import '../../api_service.dart';

class HealthQuestionnaireScreen extends StatefulWidget {
  const HealthQuestionnaireScreen({super.key});

  @override
  State<HealthQuestionnaireScreen> createState() => _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> {
  final Map<String, int> _selections = {};
  bool _isLoading = false;

  void _submitForm() async {
    // 1. Validation
    if (_selections.length < healthQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions / कृपया सभी प्रश्नों का उत्तर दें'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, String> textResponses = {};
    int totalScore = 0;

    // 2. Calculate Score
    for (var q in healthQuestions) {
      String id = q['id'];
      int selectedIndex = _selections[id]!;

      if (selectedIndex == null) {
        throw Exception("Missing answer for question $id");
      }
      
      // Save text answer
      textResponses[id] = q['options'][selectedIndex];
      
      // Add score
      //t score = q['scores'][selectedIndex];
      //talScore += score;
      totalScore += q['scores'][selectedIndex] as int;
    }

    // 3. Send to API
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      
      // if (api.currentUser == null){
      //   throw Exception("User session expired. Please login again.");
      // }
      
      await api.submitHealthProfile(textResponses, totalScore);
      
      // Success is handled by AuthWrapper redirecting to Home automatically
     // adjust based on your structure

    if (!mounted) return;

    final role = api.currentUser?.role;

    if (role == 'participant') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ParticipantDashboard()),
        (route) => false,
      );
    } 
    else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InstructorDashboard()),
        (route) => false,
      );
    } 

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } 
    //finally {
    //   if (mounted) setState(() => _isLoading = false);
    // }
  }

  // Helper to build a question card
  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final String qId = question['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...List.generate(question['options'].length, (optIndex) {
              final score = question['scores'][optIndex];
              final isPositive = score > 0;
              // Format score text: (+10) or (-5) or (0)
              final scoreText = "(${isPositive ? '+' : ''}$score)";

              // Color code the score text
              final Color scoreColor = score > 0 
                  ? Colors.green 
                  : (score < 0 ? Colors.red : Colors.grey);

              return RadioListTile<int>(
                title: Row(
                  children: [
                    Expanded(child: Text(question['options'][optIndex])),
                    Text(
                      scoreText,
                      style: TextStyle(
                        color: scoreColor, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      ),
                    ),
                  ],
                ),
                value: optIndex,
                groupValue: _selections[qId],
                activeColor: Colors.teal,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selections[qId] = val!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split questions based on logic: 
    // If the first option gives positive points (>0), it's a Positive Habit.
    // Otherwise (0 or negative), it's a Negative Habit.
    final positiveQuestions = healthQuestions.where((q) => (q['scores'][0] as int) > 0).toList();
    final negativeQuestions = healthQuestions.where((q) => (q['scores'][0] as int) <= 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swasth Jeevanshaili'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: POSITIVE ---
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "सकारात्मक आदतें (Positive Habits)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            ...positiveQuestions.map((q) => _buildQuestionCard(q)),

            const SizedBox(height: 20),

            // --- SECTION 2: NEGATIVE ---
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "नकारात्मक आदतें (Negative Habits)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
            ...negativeQuestions.map((q) => _buildQuestionCard(q)),

            const SizedBox(height: 30),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text(
                      'Submit Profile / जमा करें', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }
}