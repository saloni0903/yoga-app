import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PedometerCard extends StatefulWidget {
  const PedometerCard({super.key});

  @override
  State<PedometerCard> createState() => _PedometerCardState();
}

class _PedometerCardState extends State<PedometerCard> {
  late Future<PermissionStatus> _permissionStatusFuture;
  Stream<StepCount>? _stepCountStream;
  
  // This is the baseline step count from the last reboot, saved at/after midnight
  int _stepsAtMidnight = 0; 
  
  static const String PREF_STEPS_BASELINE = 'pedometer_baseline';
  static const String PREF_LAST_SAVED_DATE = 'pedometer_last_saved_date';

  @override
  void initState() {
    super.initState();
    // Request permission, then initialize the step counter logic
    _permissionStatusFuture = Permission.activityRecognition.request();
    _permissionStatusFuture.then((status) {
      if (status == PermissionStatus.granted) {
        // We have permission, now initialize the step baseline
        _initializeStepBaseline();
      }
    });
  }

  /// Checks if it's a new day. If so, saves the current step count as
  /// the new "midnight" baseline.
  Future<void> _initializeStepBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSavedDate = prefs.getString(PREF_LAST_SAVED_DATE);

    if (lastSavedDate == todayString) {
      // We already have a baseline for today. Just load it.
      setState(() {
        _stepsAtMidnight = prefs.getInt(PREF_STEPS_BASELINE) ?? 0;
        _stepCountStream = Pedometer.stepCountStream; // Start listening
      });
    } else {
      // It's a new day or the first time ever.
      // We need to get the *current* total steps and save it as today's baseline.
      try {
        final StepCount event = await Pedometer.stepCountStream.first;
        final int currentTotalSteps = event.steps;

        await prefs.setInt(PREF_STEPS_BASELINE, currentTotalSteps);
        await prefs.setString(PREF_LAST_SAVED_DATE, todayString);
        
        setState(() {
          _stepsAtMidnight = currentTotalSteps;
          _stepCountStream = Pedometer.stepCountStream; // Start listening
        });
      } catch (error) {
         // Handle error (e.g., sensor not available)
        setState(() {
          _stepCountStream = Stream.error('Failed to get initial steps');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.directions_walk, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            // We use a FutureBuilder to handle the permission request.
            FutureBuilder<PermissionStatus>(
              future: _permissionStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final status = snapshot.data;
                if (status == PermissionStatus.granted) {
                  // If permission is granted, check if the stream is ready
                  if (_stepCountStream == null) {
                    // This shows while _initializeStepBaseline is running
                    return const CircularProgressIndicator();
                  }

                  return StreamBuilder<StepCount>(
                    stream: _stepCountStream,
                    builder: (context, snapshot) {
                      String stepsToday = '...';
                      if (snapshot.hasData) {
                        // ✨ THE MAIN FIX IS HERE ✨
                        final int currentTotalSteps = snapshot.data!.steps;
                        // Subtract the baseline to get today's steps
                        final int steps = currentTotalSteps - _stepsAtMidnight;
                        
                        // Prevent negative numbers if sensor resets/reboots
                        stepsToday = (steps < 0 ? 0 : steps).toString(); 
                      } else if (snapshot.hasError) {
                        stepsToday = 'Sensor Error';
                      }
                      return _buildStepText(textTheme, theme, stepsToday);
                    },
                  );
                } else if (status == PermissionStatus.permanentlyDenied) {
                  return _buildPermissionDeniedText(textTheme, true);
                } else {
                  return _buildPermissionDeniedText(textTheme, false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the step count text UI
  Widget _buildStepText(TextTheme textTheme, ThemeData theme, String steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Steps Today', style: textTheme.titleLarge),
        Text(
          steps,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // Helper to build the permission denied UI
  Widget _buildPermissionDeniedText(TextTheme textTheme, bool isPermanent) {
    return Expanded(
      child: InkWell(
        onTap: isPermanent ? openAppSettings : () => setState(() {
          _permissionStatusFuture = Permission.activityRecognition.request();
          // After re-requesting, try to init baseline again if granted
          _permissionStatusFuture.then((status) {
            if (status == PermissionStatus.granted) {
              _initializeStepBaseline();
            }
          });
        }),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permission Denied', style: textTheme.titleLarge),
                Text(
                  isPermanent ? 'Tap to open settings' : 'Tap to request again',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const Spacer(),
            Icon(isPermanent ? Icons.settings : Icons.refresh, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}