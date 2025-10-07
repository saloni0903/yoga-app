import '../../api_service.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';
import '../../models/yoga_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreateGroupScreen extends StatefulWidget {
  final YogaGroup? existingGroup;

  const CreateGroupScreen({super.key, this.existingGroup});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _recurrenceRule = 'NONE';
  String _repeatRule = 'weekly';

  final List<String> _selectedDays = [];

  // Text Controllers
  final _groupNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationTextController = TextEditingController();
  final _timingsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _sessionDurationController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _equipmentController = TextEditingController();

  // Dropdown Values
  String _selectedYogaStyle = 'hatha';
  String _selectedDifficultyLevel = 'all-levels';
  bool _isActive = true;
  bool _isLoading = false;

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Basic Info'),
        content: Column(
          children: [
            TextFormField(
              controller: _groupNameController,
              decoration: InputDecoration(labelText: 'Group Name *'),
              validator: _validateGroupName,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedYogaStyle,
              decoration: InputDecoration(labelText: 'Yoga Style'),
              items: _yogaStyles
                  .map(
                    (style) => DropdownMenuItem(
                      value: style,
                      child: Text(style.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedYogaStyle = value ?? 'hatha'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficultyLevel,
              decoration: InputDecoration(labelText: 'Difficulty Level'),
              items: _difficultyLevels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(
                () => _selectedDifficultyLevel = value ?? 'all-levels',
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Location'),
        content: Column(
          children: [
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'City *'),
              validator: (v) => _validateRequired(v, 'City'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationTextController,
              decoration: InputDecoration(labelText: 'Address *'),
              validator: _validateLocationText,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _fetchLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _openMapPicker,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pick on Map'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Schedule & Details'),
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _startTime == null
                          ? 'Start Time'
                          : DateFormat('hh:mm a').format(
                              DateTime(
                                2020,
                                1,
                                1,
                                _startTime!.hour,
                                _startTime!.minute,
                              ),
                            ),
                    ),
                    onPressed: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _endTime == null
                          ? 'End Time'
                          : DateFormat('hh:mm a').format(
                              DateTime(
                                2020,
                                1,
                                1,
                                _endTime!.hour,
                                _endTime!.minute,
                              ),
                            ),
                    ),
                    onPressed: _pickEndTime,
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 16),
            // TextFormField(
            //   controller: _sessionDurationController,
            //   decoration: InputDecoration(labelText: 'Duration (minutes) *'),
            //   validator: _validateSessionDuration,
            //   keyboardType: TextInputType.number,
            // ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: InputDecoration(labelText: 'Max Participants *'),
              validator: _validateMaxParticipants,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per Session *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: _validatePrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? now,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365 * 2),
      ), // Allow scheduling up to 2 years in advance
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _openMapPicker() async {
    LatLng initialPoint =
        _selectedLocation ??
        LatLng(
          double.tryParse(_latitudeController.text) ?? 22.7196,
          double.tryParse(_longitudeController.text) ?? 75.8577,
        );

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        LatLng tappedPoint =
            initialPoint; // To hold the state within the dialog
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Select Location'),
              contentPadding: const EdgeInsets.all(0),
              content: SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.6, // Use 60% of screen height
                width:
                    MediaQuery.of(context).size.width *
                    0.9, // Use 90% of screen width
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialPoint,
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all, // <-- ENABLES ZOOM AND DRAG
                    ),
                    onTap: (tapPosition, point) {
                      setStateInDialog(() {
                        tappedPoint = point; // Update the tapped point visually
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: tappedPoint,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FilledButton(
                  child: const Text('Select'),
                  onPressed: () => Navigator.of(context).pop(tappedPoint),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _selectedLocation = result;
        _latitudeController.text = result.latitude.toStringAsFixed(5);
        _longitudeController.text = result.longitude.toStringAsFixed(5);
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final locationData = await apiService.reverseGeocode(
          latitude: result.latitude,
          longitude: result.longitude,
        );
        // **THIS IS THE FIX**
        // Correctly use the map to populate both fields
        setState(() {
          _locationTextController.text = locationData['address'] ?? '';
          _locationController.text = locationData['city'] ?? '';
        });
      } catch (e) {
        if (mounted) {
          _showError('Could not fetch address for the selected point.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay(hour: 6, minute: 30),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
      _updateTimingsField();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: 7, minute: 30),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
      _updateTimingsField();
    }
  }

  void _updateTimingsField() {
    // This will now build a string like "Mon, Wed, Fri at 7:00 AM"
    if (_startTime != null && _endTime != null && _selectedDays.isNotEmpty) {
      // Sort the days to a consistent order (Mon, Tue, Wed...)
      const dayOrder = {
        "Mon": 1,
        "Tue": 2,
        "Wed": 3,
        "Thu": 4,
        "Fri": 5,
        "Sat": 6,
        "Sun": 7,
      };
      _selectedDays.sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));

      final daysString = _selectedDays.join(', ');
      final startTimeString = DateFormat(
        'h:mm a',
      ).format(DateTime(2020, 1, 1, _startTime!.hour, _startTime!.minute));
      final endTimeString = DateFormat(
        'h:mm a',
      ).format(DateTime(2020, 1, 1, _endTime!.hour, _endTime!.minute));

      setState(() {
        _timingsController.text =
            '$daysString from $startTimeString to $endTimeString';
      });
    } else {
      setState(() {
        _timingsController.text = '';
      });
    }
  }

  final List<String> _yogaStyles = [
    'hatha',
    'vinyasa',
    'ashtanga',
    'iyengar',
    'bikram',
    'yin',
    'restorative',
    'power',
    'other',
  ];

  final List<String> _difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'all-levels',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      // Populate form for editing
      _groupNameController.text = widget.existingGroup!.name;
      _locationController.text = widget.existingGroup!.location;
      _locationTextController.text = widget.existingGroup!.locationText;
      _timingsController.text = widget.existingGroup!.timingText;
      _descriptionController.text = widget.existingGroup!.description ?? '';
    }
    _initializeForm();
  }

  void _initializeForm() {
    final existing = widget.existingGroup;
    if (existing != null) {
      // Edit mode - populate existing values
      _groupNameController.text = existing.name;
      _locationController.text = existing.location ?? '';
      _locationTextController.text = existing.locationText;
      _timingsController.text = existing.timingText;
      _descriptionController.text = existing.description ?? '';
      _maxParticipantsController.text = existing.maxParticipants.toString();
      // _sessionDurationController.text = existing.sessionDuration.toString();
      _priceController.text = existing.pricePerSession.toString();
      _currencyController.text = existing.currency ?? 'INR';
      _selectedYogaStyle = existing.yogaStyle;
      _selectedDifficultyLevel = existing.difficultyLevel;
      _isActive = existing.isActive;
      _requirementsController.text = (existing.requirements ?? []).join(', ');
      _equipmentController.text = (existing.equipmentNeeded ?? []).join(', ');
      _latitudeController.text = existing.latitude?.toString() ?? '';
      _longitudeController.text = existing.longitude?.toString() ?? '';
      _recurrenceRule = existing.schedule.recurrence;

      _startTime = TimeOfDay(
        hour: int.parse(existing.schedule.startTime.split(':')[0]),
        minute: int.parse(existing.schedule.startTime.split(':')[1]),
      );
      _endTime = TimeOfDay(
        hour: int.parse(existing.schedule.endTime.split(':')[0]),
        minute: int.parse(existing.schedule.endTime.split(':')[1]),
      );
      _startDate = existing.schedule.startDate;
      _endDate = existing.schedule.endDate;

      // Map full day names from backend to short day names for UI
      const dayMap = {
        "Monday": "Mon",
        "Tuesday": "Tue",
        "Wednesday": "Wed",
        "Thursday": "Thu",
        "Friday": "Fri",
        "Saturday": "Sat",
        "Sunday": "Sun",
      };
      _selectedDays.addAll(existing.schedule.days.map((day) => dayMap[day]!));
    } else {
      // Create mode - set defaults
      _maxParticipantsController.text = '20';
      // _sessionDurationController.text = '60';
      _priceController.text = '0';
      _currencyController.text = 'INR';
      _latitudeController.text = '22.7196'; // Default to Indore
      _longitudeController.text = '75.8577';
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateGroupName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Group name is required';
    if (v.length < 2) return 'Group name must be at least 2 characters';
    if (v.length > 100) return 'Group name cannot exceed 100 characters';
    return null;
  }

  String? _validateLocationText(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Location text is required';
    if (v.length > 500) return 'Location text cannot exceed 500 characters';
    return null;
  }

  String? _validateDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 1000) return 'Description cannot exceed 1000 characters';
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Latitude is required';
    final lat = double.tryParse(value.trim());
    if (lat == null) return 'Invalid latitude format';
    if (lat < -90 || lat > 90) return 'Latitude must be between -90 and 90';
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Longitude is required';
    final lng = double.tryParse(value.trim());
    if (lng == null) return 'Invalid longitude format';
    if (lng < -180 || lng > 180)
      return 'Longitude must be between -180 and 180';
    return null;
  }

  String? _validateMaxParticipants(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Max participants is required';
    final num = int.tryParse(value.trim());
    if (num == null) return 'Invalid number format';
    if (num < 1 || num > 100)
      return 'Max participants must be between 1 and 100';
    return null;
  }

  String? _validateSessionDuration(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Session duration is required';
    final num = int.tryParse(value.trim());
    if (num == null) return 'Invalid number format';
    if (num < 15 || num > 180)
      return 'Duration must be between 15 and 180 minutes';
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final price = double.tryParse(value.trim());
    if (price == null) return 'Invalid price format';
    if (price < 0) return 'Price cannot be negative';
    return null;
  }

  String? _validateCurrency(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Currency is required';
    if (v.length > 3) return 'Currency code cannot exceed 3 characters';
    return null;
  }

  String? _validateTimings(String? value) {
    final v = value?.trim() ?? '';
    final regex = RegExp(
      r'^(1[0-2]|0[1-9]):[0-5][0-9] (AM|PM) - (1[0-2]|0[1-9]):[0-5][0-9] (AM|PM)$',
    );
    if (v.isEmpty) return 'Timings are required';
    if (!regex.hasMatch(v)) return 'Format: HH:MM AM/PM - HH:MM AM/PM';
    if (v.length > 200) return 'Timings cannot exceed 200 characters';
    return null;
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      // 1. PERMISSION CHECKS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // 2. GET LOCATION (Platform-Aware)
      Position position;
      if (kIsWeb) {
        // On web, get current position directly.
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } else {
        // On mobile, try for a fast last-known position first.
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          // Fallback to current position if no last-known is available.
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium, // Medium is faster
          );
        }
      }

      // 3. REVERSE GEOCODE AND UPDATE UI
      final apiService = Provider.of<ApiService>(context, listen: false);
      final locationData = await apiService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(5);
        _longitudeController.text = position.longitude.toStringAsFixed(5);
        _locationTextController.text = locationData['address'] ?? '';
        _locationController.text = locationData['city'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGroup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startTime == null ||
        _endTime == null ||
        _startDate == null ||
        _endDate == null ||
        _selectedDays.isEmpty) {
      _showError(
        'Please complete all schedule fields: days, times, and date range.',
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be before the start date.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Automatically calculate duration in minutes
      final startDateTime = DateTime(
        2025,
        1,
        1,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        2025,
        1,
        1,
        _endTime!.hour,
        _endTime!.minute,
      );
      int durationInMinutes = endDateTime.difference(startDateTime).inMinutes;
      if (durationInMinutes <= 0) {
        durationInMinutes += 1440; // Add 24 hours for overnight sessions
      }

      // Map short day names back to full names for the backend
      const dayMap = {
        "Mon": "Monday",
        "Tue": "Tuesday",
        "Wed": "Wednesday",
        "Thu": "Thursday",
        "Fri": "Friday",
        "Sat": "Saturday",
        "Sun": "Sunday",
      };
      final fullDayNames = _selectedDays.map((day) => dayMap[day]!).toList();

      // CONSTRUCT THE SCHEDULE OBJECT
      final scheduleObject = Schedule(
        startTime:
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        days: fullDayNames,
        startDate: _startDate!,
        endDate: _endDate!,
        recurrence: _recurrenceRule,
      );

      final apiService = Provider.of<ApiService>(context, listen: false);

      // Common data from controllers
      final commonData = {
        'groupName': _groupNameController.text.trim(),
        'location': _locationController.text.trim(),
        'locationText': _locationTextController.text.trim(),
        'latitude': double.parse(_latitudeController.text.trim()),
        'longitude': double.parse(_longitudeController.text.trim()),
        'description': _descriptionController.text.trim(),
        'maxParticipants': int.parse(_maxParticipantsController.text.trim()),
        'yogaStyle': _selectedYogaStyle,
        'difficultyLevel': _selectedDifficultyLevel,
        'sessionDuration': durationInMinutes,
        'pricePerSession': double.parse(_priceController.text.trim()),
        'currency': _currencyController.text.trim(),
        'requirements': _requirementsController.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'equipmentNeeded': _equipmentController.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'isActive': _isActive,
      };

      if (widget.existingGroup == null) {
        // --- CREATE A NEW GROUP ---
        // Pass the scheduleObject directly here, along with other data
        await apiService.createGroup(
          schedule: scheduleObject, // <-- FIX: Pass the object directly
          // Pass the rest of the data
          groupName: commonData['groupName'] as String,
          location: commonData['location'] as String,
          locationText: commonData['locationText'] as String,
          latitude: commonData['latitude'] as double,
          longitude: commonData['longitude'] as double,
          description: commonData['description'] as String,
          maxParticipants: commonData['maxParticipants'] as int,
          yogaStyle: commonData['yogaStyle'] as String,
          difficultyLevel: commonData['difficultyLevel'] as String,
          sessionDuration: commonData['sessionDuration'] as int,
          pricePerSession: commonData['pricePerSession'] as double,
          currency: commonData['currency'] as String,
          requirements: commonData['requirements'] as List<String>,
          equipmentNeeded: commonData['equipmentNeeded'] as List<String>,
          isActive: commonData['isActive'] as bool,
        );
      } else {
        // --- UPDATE AN EXISTING GROUP ---
        // Pass the scheduleObject directly here too
        await apiService.updateGroup(
          id: widget.existingGroup!.id,
          schedule: scheduleObject, // <-- FIX: Pass the object directly
          // Pass the rest of the data
          groupName: commonData['groupName'] as String,
          location: commonData['location'] as String,
          locationText: commonData['locationText'] as String,
          latitude: commonData['latitude'] as double,
          longitude: commonData['longitude'] as double,
          description: commonData['description'] as String,
          maxParticipants: commonData['maxParticipants'] as int,
          yogaStyle: commonData['yogaStyle'] as String,
          difficultyLevel: commonData['difficultyLevel'] as String,
          sessionDuration: commonData['sessionDuration'] as int,
          pricePerSession: commonData['pricePerSession'] as double,
          currency: commonData['currency'] as String,
          requirements: commonData['requirements'] as List<String>,
          equipmentNeeded: commonData['equipmentNeeded'] as List<String>,
          isActive: commonData['isActive'] as bool,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingGroup == null
                ? 'Group created successfully!'
                : 'Group updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        _showError(
          'Save failed: ${e.toString().replaceFirst('Exception: ', '')}',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _locationController.dispose();
    _locationTextController.dispose();
    _timingsController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _maxParticipantsController.dispose();
    // _sessionDurationController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _requirementsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGroup != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Group' : 'Create New Group'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Basic Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Group Name
                      TextFormField(
                        controller: _groupNameController,
                        decoration: InputDecoration(
                          labelText: 'Group Name *',
                          helperText:
                              'Enter a descriptive name for your yoga group',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: _validateGroupName,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Location (Short Name)
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          helperText: 'e.g., "Indore", "Mumbai"',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) => _validateRequired(v, 'Location'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Location Text (Detailed)
                      TextFormField(
                        controller: _locationTextController,
                        decoration: InputDecoration(
                          labelText: 'Address *',
                          helperText: 'Full address',
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: _validateLocationText,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Coordinates Row
                      // Location Picker Section
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _fetchLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Use Current Location'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _openMapPicker,
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Pick on Map'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Schedule Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Schedule & Duration',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Class Days *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children:
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ].map((day) {
                              final isSelected = _selectedDays.contains(day);
                              return FilterChip(
                                label: Text(day),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDays.add(day);
                                    } else {
                                      _selectedDays.remove(day);
                                    }
                                    _updateTimingsField();
                                  });
                                },
                                selectedColor: theme.colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : null,
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Select Class Date Range *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _startDate == null
                                    ? 'Start Date'
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_startDate!),
                              ),
                              onPressed: () =>
                                  _pickDate(true), // For Start Date
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                              icon: const Icon(Icons.event),
                              label: Text(
                                _endDate == null
                                    ? 'End Date'
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_endDate!),
                              ),
                              onPressed: () => _pickDate(false), // For End Date
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Select Class Time *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _startTime == null
                              ? 'Select a Start Time'
                              : 'Starts at ${DateFormat('h:mm a').format(DateTime(2020, 1, 1, _startTime!.hour, _startTime!.minute))}',
                        ),
                        onPressed: _pickStartTime,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _endTime == null
                              ? 'Select an End Time'
                              : 'Ends at ${DateFormat('h:mm a').format(DateTime(2020, 1, 1, _endTime!.hour, _endTime!.minute))}',
                        ),
                        onPressed: _pickEndTime,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timingsController,
                        decoration: InputDecoration(
                          labelText: 'Generated Schedule *',
                          helperText: 'Auto-generated from your selections',
                          prefixIcon: Icon(Icons.event_repeat),
                        ),
                        readOnly: true,
                        validator: (v) => _validateRequired(v, 'Schedule'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              // controller: _sessionDurationController,
                              decoration: InputDecoration(
                                labelText: 'Duration (minutes) *',
                                prefixIcon: Icon(Icons.timer),
                              ),
                              // validator: _validateSessionDuration,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxParticipantsController,
                              decoration: InputDecoration(
                                labelText: 'Max Participants *',
                                prefixIcon: Icon(Icons.people),
                              ),
                              validator: _validateMaxParticipants,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Yoga Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.self_improvement,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yoga Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Yoga Style Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedYogaStyle,
                        decoration: InputDecoration(
                          labelText: 'Yoga Style',
                          prefixIcon: Icon(Icons.spa),
                        ),
                        items: _yogaStyles.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(style.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedYogaStyle = value ?? 'hatha');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Difficulty Level Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDifficultyLevel,
                        decoration: InputDecoration(
                          labelText: 'Difficulty Level',
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        items: _difficultyLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(
                            () => _selectedDifficultyLevel =
                                value ?? 'all-levels',
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          helperText:
                              'Describe your yoga group and what makes it special',
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: _validateDescription,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pricing Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pricing',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price and Currency Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price per Session *',
                                helperText: 'Enter Rs. 0 for free',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              validator: _validatePrice,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Additional Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Additional Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Requirements
                      TextFormField(
                        controller: _requirementsController,
                        decoration: InputDecoration(
                          labelText: 'Requirements (Optional)',
                          helperText: 'Separate multiple items with commas',
                          prefixIcon: Icon(Icons.checklist),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Equipment Needed
                      TextFormField(
                        controller: _equipmentController,
                        decoration: InputDecoration(
                          labelText: 'Equipment Needed (Optional)',
                          helperText: 'Separate multiple items with commas',
                          prefixIcon: Icon(Icons.fitness_center),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Active Status Switch
                      SwitchListTile(
                        title: const Text('Active Group'),
                        subtitle: const Text(
                          'Participants can join this group',
                        ),
                        value: _isActive,
                        onChanged: (bool value) {
                          setState(() => _isActive = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _saveGroup,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isEdit ? Icons.save : Icons.add),
                  label: Text(
                    _isLoading
                        ? (isEdit ? 'Updating...' : 'Creating...')
                        : (isEdit ? 'Save Changes' : 'Create Group'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
