import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
// lib/utils/date_helper.dart


class DateHelper {
  // This function finds the next session date based on a text schedule
  static String getNextSessionText(String scheduleText) {
    // Map short day names to weekday numbers (Monday=1, Sunday=7)
    const dayMap = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    };

    try {
      // Example format: "Mon, Wed, Fri at 7:00 AM"
      final parts = scheduleText.split(' at ');
      if (parts.length != 2) return 'Schedule unavailable';

      final daysPart = parts[0];
      final timePart = parts[1];

      // Parse the time
      final timeFormat = DateFormat('h:mm a');
      final sessionTime = timeFormat.parse(timePart);
      
      // Get the scheduled weekdays
      final scheduledDays = dayMap.entries
          .where((entry) => daysPart.contains(entry.key))
          .map((entry) => entry.value)
          .toList();

      if (scheduledDays.isEmpty) return 'Schedule unavailable';

      // Find the next upcoming session
      final now = DateTime.now();
      DateTime nextSession = now;

      for (int i = 0; i < 14; i++) { // Check over the next 2 weeks
        DateTime potentialDate = DateTime.now().add(Duration(days: i));
        
        if (scheduledDays.contains(potentialDate.weekday)) {
          // We found a valid day. Now combine it with the session time.
          DateTime potentialSession = DateTime(
            potentialDate.year,
            potentialDate.month,
            potentialDate.day,
            sessionTime.hour,
            sessionTime.minute,
          );

          // If this session is in the future, it's our candidate
          if (potentialSession.isAfter(now)) {
            nextSession = potentialSession;
            
            // Check if it's today or tomorrow for user-friendly text
            if (nextSession.day == now.day && nextSession.month == now.month) {
              return 'Next: Today at ${DateFormat('h:mm a').format(nextSession)}';
            } else if (nextSession.day == now.add(const Duration(days: 1)).day) {
              return 'Next: Tomorrow at ${DateFormat('h:mm a').format(nextSession)}';
            } else {
              // Otherwise, show the day of the week
              return 'Next: ${DateFormat('EEEE, h:mm a').format(nextSession)}';
            }
          }
        }
      }

      return 'Schedule unavailable'; // Fallback
    } catch (e) {
      debugPrint('Error parsing schedule text: $e');
      return 'Invalid schedule format';
    }
  }
}