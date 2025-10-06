// lib/widgets/streak_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart'; // Make sure to import your model

class AttendanceDialog extends StatelessWidget {
  // Accepts a list of real attendance records
  final List<AttendanceRecord> attendanceHistory;

  const AttendanceDialog({super.key, required this.attendanceHistory});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recent Attendance', textAlign: TextAlign.center),
      content: SingleChildScrollView( // Added for safety if the list is long
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attendanceHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No recent attendance found.'),
              )
            else
              ...attendanceHistory.map((record) {
                // FIXED: Uses the correct field name 'attendanceType'
                final isPresent = record.attendanceType == 'present' || record.attendanceType == 'late';
                return ListTile(
                  leading: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green.shade400 : Colors.red.shade300,
                  ),
                  title: Text(DateFormat('EEEE').format(record.sessionDate)), // e.g., 'Monday'
                  trailing: Text(
                    DateFormat('MMM dd, yyyy').format(record.sessionDate), // e.g., 'Oct 06, 2025'
                    style: TextStyle(
                      color: isPresent ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// // lib/widgets/streak_dialog.dart
// import 'package:flutter/material.dart';
// import 'dart:math';

// // Dummy data model
// class StreakDay {
//   final String day;
//   final int steps;
//   final bool goalMet;

//   StreakDay({required this.day, required this.steps, required this.goalMet});
// }

// class StreakDialog extends StatelessWidget {
//   const StreakDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // --- DUMMY DATA ---
//     final List<StreakDay> streakData = [
//       StreakDay(day: 'Mon', steps: 9045, goalMet: true),
//       StreakDay(day: 'Tue', steps: 8521, goalMet: true),
//       StreakDay(day: 'Wed', steps: 10012, goalMet: true),
//       StreakDay(day: 'Thu', steps: 6780, goalMet: false),
//       StreakDay(day: 'Fri', steps: 8900, goalMet: true),
//       StreakDay(day: 'Sat', steps: 12345, goalMet: true),
//       StreakDay(day: 'Sun', steps: 7500, goalMet: false),
//     ];
//     // ------------------

//     final bool allGoalsMet = streakData.every((day) => day.goalMet);

//     return AlertDialog(
//       title: const Text('7-Day Step Streak', textAlign: TextAlign.center),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           for (var dayData in streakData)
//             ListTile(
//               leading: Icon(
//                 dayData.goalMet ? Icons.check_circle : Icons.cancel,
//                 color: dayData.goalMet ? Colors.green.shade400 : Colors.red.shade300,
//               ),
//               title: Text(dayData.day),
//               trailing: Text(
//                 '${dayData.steps} steps',
//                 style: TextStyle(
//                   color: dayData.goalMet ? Colors.black87 : Colors.grey.shade600,
//                   fontWeight: dayData.goalMet ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//             ),
//           const Divider(height: 24),
//           if (allGoalsMet)
//             const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.star, color: Colors.amber),
//                 SizedBox(width: 8),
//                 Text('Reward Unlocked!', style: TextStyle(fontWeight: FontWeight.bold)),
//               ],
//             )
//           else
//             const Text('Complete all 7 days to unlock a reward!'),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Close'),
//         ),
//       ],
//     );
//   }
// }