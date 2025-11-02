// lib/models/yoga_group.dart
import 'package:intl/intl.dart';

class Schedule {
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final List<String> days; // ["Monday", "Friday"]
  final DateTime startDate;
  final DateTime endDate;

  Schedule({
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.startDate,
    required this.endDate,
  });

  factory Schedule.fromJson(Map<String, dynamic> j) {
    return Schedule(
      startTime: j['startTime'] ?? '00:00',
      endTime: j['endTime'] ?? '00:00',
      days: List<String>.from(j['days'] ?? []),
      startDate: DateTime.tryParse(j['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(j['endDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'days': days,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

class YogaGroup {
  final String id;
  final String name;
  final String groupType;
  final String location;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final Schedule schedule;
  final String color;
  final String yogaStyle;
  final String difficultyLevel;
  final bool isActive;
  final String? description;
  final int maxParticipants;
  final double pricePerSession;
  final String currency;
  final List<String> requirements;
  final List<String> equipmentNeeded;
  final int? memberCount;
  final String instructorId;
  final String? instructorName;
  final String? instructorEmail;
  final double? distance;
  final String? meetLink;

  int get sessionDurationInMinutes {
    if (schedule.startTime.isEmpty || schedule.endTime.isEmpty) {
      return 0;
    }
    try {
      final startParts = schedule.startTime.split(':').map(int.parse).toList();
      final endParts = schedule.endTime.split(':').map(int.parse).toList();

      // Create DateTime objects on a dummy date to calculate the difference
      final startDate = DateTime(2025, 1, 1, startParts[0], startParts[1]);
      final endDate = DateTime(2025, 1, 1, endParts[0], endParts[1]);

      final duration = endDate.difference(startDate);

      // Handle overnight sessions (e.g., 10 PM to 1 AM)
      if (duration.isNegative) {
        return duration.inMinutes + (24 * 60);
      }
      return duration.inMinutes;
    } catch (e) {
      return 0; // Return 0 if parsing fails
    }
  }

  String get timingText {
    if (schedule.days.isEmpty || schedule.startTime.isEmpty) {
      return 'No schedule set';
    }
    // Sort the days to a consistent order (Mon, Tue, Wed...)
    const dayOrder = {
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
      "Saturday": 6,
      "Sunday": 7,
    };
    final sortedDays = List<String>.from(schedule.days)
      ..sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));

    final shortDays = sortedDays.map((d) => d.substring(0, 3)).join(', ');

    final startTime = DateFormat(
      'h:mm a',
    ).format(DateTime.parse('2025-01-01T${schedule.startTime}:00'));

    return '$shortDays at $startTime';
  }

  String get displayLocation {
    if (groupType == 'online') {
      return 'Online';
    }
    // locationText will be populated by the backend
    return locationText.isNotEmpty ? locationText : 'No location set';
  }

  YogaGroup({
    this.distance,
    required this.id,
    required this.name,
    required this.groupType,
    required this.location,
    required this.locationText,
    this.latitude,
    this.longitude,
    required this.schedule,
    required this.yogaStyle,
    required this.difficultyLevel,
    required this.isActive,
    this.description,
    required this.maxParticipants,
    required this.pricePerSession,
    required this.currency,
    this.requirements = const [],
    this.equipmentNeeded = const [],
    this.memberCount,
    required this.instructorId,
    this.instructorName,
    this.instructorEmail,
    required this.color,
    this.meetLink,
  });

  factory YogaGroup.fromJson(Map<String, dynamic> j) {
    String? tempInstructorName;
    String? tempInstructorEmail;
    String getInstructorId(dynamic instructorField) {
      if (instructorField is Map) {
        tempInstructorName =
            '${instructorField['firstName'] ?? ''} ${instructorField['lastName'] ?? ''}'
                .trim();
        tempInstructorEmail = instructorField['email']?.toString();
        return instructorField['_id']?.toString() ?? '';
      }
      return instructorField?.toString() ?? '';
    }

    double? parsedLatitude;
    double? parsedLongitude;

    // Check for GeoJSON-style location
    if (j['location'] is Map && j['location']['coordinates'] is List) {
      final coords = List<dynamic>.from(j['location']['coordinates']);

      // Standard GeoJSON is [longitude, latitude] (index 0 is lon, index 1 is lat)
      if (coords.length == 2) {
        parsedLongitude = (coords[0] as num?)?.toDouble();
        parsedLatitude = (coords[1] as num?)?.toDouble();
      }
    }

    return YogaGroup(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['group_name'] ?? '').toString(),
      groupType: j['groupType'] as String? ?? 'offline',
      location:
          (j['location']
                      is Map // <-- ADD 'location:' KEY HERE
                  ? (j['location']['coordinates']?.toString() ?? '')
                  : (j['location'] ?? ''))
              .toString(),
      locationText:
          (j['location'] is Map
                  ? (j['location']['address'] ?? '').toString()
                  : (j['location_text'] ?? ''))
              .toString(),
      latitude: parsedLatitude ?? (j['latitude'] as num?)?.toDouble(),
      longitude: parsedLongitude ?? (j['longitude'] as num?)?.toDouble(),
      schedule: Schedule.fromJson(j['schedule'] ?? {}),
      yogaStyle: (j['yoga_style'] ?? 'hatha').toString(),
      color: (j['color'] ?? '#4CAF50').toString(),
      difficultyLevel: (j['difficulty_level'] ?? 'all-levels').toString(),
      isActive: (j['is_active'] ?? true) == true,
      description: j['description']?.toString(),
      distance: (j['distance'] as num?)?.toDouble(),
      maxParticipants: (j['max_participants'] ?? 20) as int,
      pricePerSession: ((j['price_per_session'] ?? 0) as num).toDouble(),
      currency: (j['currency'] ?? 'INR').toString(),
      requirements: List<String>.from(j['requirements'] ?? []),
      equipmentNeeded: List<String>.from(j['equipment_needed'] ?? []),
      instructorId: getInstructorId(j['instructor_id']),
      memberCount: j['memberCount'] as int?,
      instructorName: tempInstructorName,
      instructorEmail: tempInstructorEmail,
      meetLink: j['meetLink']?.toString(),
    );
  }
}
