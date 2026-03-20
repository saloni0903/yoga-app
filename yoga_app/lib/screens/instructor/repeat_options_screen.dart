// lib/screens/instructor/repeat_options_screen.dart

import 'package:flutter/material.dart';

class RepeatOptionsScreen extends StatefulWidget {
  final List<String> selectedDays;

  const RepeatOptionsScreen({super.key, required this.selectedDays});

  @override
  _RepeatOptionsScreenState createState() => _RepeatOptionsScreenState();
}

class _RepeatOptionsScreenState extends State<RepeatOptionsScreen> {
  late List<String> _selectedDays;
  String _repeatType = 'none'; // none, daily, weekly, monthly, yearly

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
    
    // Determine current repeat type
    if (_selectedDays.isEmpty) {
      _repeatType = 'none';
    } else if (_selectedDays.length == 7) {
      _repeatType = 'daily';
    } else {
      _repeatType = 'weekly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repetition'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selectedDays),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Description text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getDescriptionText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          
          // Repeat options
          // Expanded(
          //   child: RadioGroup<String>(
          //     value: _repeatType,
          //     onChanged: (value) {
          //       setState(() {
          //         _repeatType = value!;
          //         if (value == 'daily') {
          //           _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          //         } else if (value == 'weekly' && _selectedDays.isEmpty) {
          //           // Set to current day if no days selected
          //           final dayMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
          //           _selectedDays = [dayMap[DateTime.now().weekday]!];
          //         } else if (value == 'none' || value == 'monthly' || value == 'yearly') {
          //           _selectedDays.clear();
          //         }
          //       });
          //     },
          //     children: [
          //       RadioListTile<String>(
          //         title: const Text('Don\'t repeat'),
          //         value: 'none',
          //       ),
          //       RadioListTile<String>(
          //         title: const Text('Every day'),
          //         value: 'daily',
          //       ),
          //       RadioListTile<String>(
          //         title: const Text('Every week'),
          //         value: 'weekly',
          //       ),
          //       RadioListTile<String>(
          //         title: const Text('Every month'),
          //         value: 'monthly',
          //       ),
          //       RadioListTile<String>(
          //         title: const Text('Every year'),
          //         value: 'yearly',
          //       ),
          //     ],
          //   ),
          // ),
          
          // Day selection for weekly (outside RadioGroup)
          if (_repeatType == 'weekly')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Repeat on:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return ChoiceChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                            } else if (_selectedDays.length > 1) {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.onPrimary : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getDescriptionText() {
    switch (_repeatType) {
      case 'none':
        return 'This event doesn\'t repeat.';
      case 'daily':
        return 'This event will repeat every 1 day.';
      case 'weekly':
        if (_selectedDays.isEmpty) {
          return 'This event will repeat every 1 week.';
        } else {
          final dayNames = _selectedDays.join(', ');
          return 'This event will repeat every 1 week on $dayNames.';
        }
      case 'monthly':
        return 'This event will repeat every 1 month.';
      case 'yearly':
        return 'This event will repeat every 1 year.';
      default:
        return 'This event doesn\'t repeat.';
    }
  }
}