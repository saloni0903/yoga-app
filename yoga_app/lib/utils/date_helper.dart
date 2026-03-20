import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/yoga_group.dart'; // Import the new model
// REPLACE the entire contents of the file

class DateHelper {
  static String getNextSessionTextFromSchedule(Schedule schedule) {
    try {
      const dayMap = {
        'Monday': DateTime.monday,
        'Tuesday': DateTime.tuesday,
        'Wednesday': DateTime.wednesday,
        'Thursday': DateTime.thursday,
        'Friday': DateTime.friday,
        'Saturday': DateTime.saturday,
        'Sunday': DateTime.sunday,
      };

      final scheduledWeekdays = schedule.days.map((d) => dayMap[d]).toList();
      if (scheduledWeekdays.isEmpty) return 'No scheduled days';
      
      final now = DateTime.now();
      final [hour, minute] = schedule.startTime.split(':').map(int.parse).toList();

      for (int i = 0; i < 14; i++) { // Check up to 2 weeks ahead
        DateTime potentialDate = DateTime(now.year, now.month, now.day).add(Duration(days: i));
        
        // Check if this date is within the group's active range
        if (potentialDate.isBefore(schedule.startDate) || potentialDate.isAfter(schedule.endDate)) {
            continue;
        }
        
        if (scheduledWeekdays.contains(potentialDate.weekday)) {
          DateTime potentialSession = DateTime(
            potentialDate.year,
            potentialDate.month,
            potentialDate.day,
            hour,
            minute,
          );

          if (potentialSession.isAfter(now)) {
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
            final sessionDay = DateTime(potentialSession.year, potentialSession.month, potentialSession.day);

            if (sessionDay.isAtSameMomentAs(today)) {
              return 'Next: Today at ${DateFormat('h:mm a').format(potentialSession)}';
            } else if (sessionDay.isAtSameMomentAs(tomorrow)) {
              return 'Next: Tomorrow at ${DateFormat('h:mm a').format(potentialSession)}';
            } else {
              return 'Next: ${DateFormat('EEEE, h:mm a').format(potentialSession)}';
            }
          }
        }
      }

      return 'No upcoming sessions'; // Fallback
    } catch (e) {
      debugPrint('Error calculating next session: $e');
      return 'Schedule error';
    }
  }
}