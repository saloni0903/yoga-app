// lib/screens/health_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    if (_selections.length < healthQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions / कृपया सभी प्रश्नों का उत्तर दें')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, String> textResponses = {};
    int totalScore = 0;

    for (var q in healthQuestions) {
      String id = q['id'];
      int selectedIndex = _selections[id]!;
      textResponses[id] = q['options'][selectedIndex];
      int score = q['scores'][selectedIndex];
      totalScore += score;
    }

    try {
      // Use Provider to call the ApiService we updated
      await Provider.of<ApiService>(context, listen: false)
          .submitHealthProfile(textResponses, totalScore);

      // No navigation needed here! 
      // ApiService.notifyListeners() will trigger AuthWrapper to switch to HomeScreen automatically.
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swasth Jeevanshaili (Health Profile)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: healthQuestions.length + 1,
        itemBuilder: (context, index) {
          if (index == healthQuestions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Submit / जमा करें'),
              ),
            );
          }

          final question = healthQuestions[index];
          final String qId = question['id'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question['question'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(question['options'].length, (optIndex) {
                    return RadioListTile<int>(
                      title: Text(question['options'][optIndex]),
                      value: optIndex,
                      groupValue: _selections[qId],
                      onChanged: (val) => setState(() => _selections[qId] = val!),
                      dense: true,
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}