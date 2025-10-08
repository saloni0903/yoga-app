import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import 'repeat_options_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final YogaGroup? existingGroup;

  const CreateGroupScreen({super.key, this.existingGroup});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  // Basic Info
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Location
  final _locationTextController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Schedule
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<String> _selectedDays = [];

  // Details
  final _maxParticipantsController = TextEditingController();
  final _sessionDurationController = TextEditingController(); // Auto-calculated
  final _priceController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _equipmentController = TextEditingController();
  
  // State Variables
  String _selectedYogaStyle = 'hatha';
  String _selectedDifficultyLevel = 'all-levels';
  bool _isActive = true;
  bool _isLoading = false;
  Color _groupColor = const Color(0xFF4CAF50);
  LatLng? _selectedLocation;
  
  // Data for Dropdowns
  final List<String> _yogaStyles = const ['hatha', 'vinyasa', 'ashtanga', 'iyengar', 'kundalini', 'bikram', 'restorative'];
  final List<String> _difficultyLevels = const ['all-levels', 'beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;

    final existing = widget.existingGroup;
    if (existing != null) {
      // --- EDIT MODE ---
      _groupNameController.text = existing.name;
      _locationTextController.text = existing.locationText;
      _descriptionController.text = existing.description ?? '';
      _maxParticipantsController.text = existing.maxParticipants.toString();
      _priceController.text = existing.pricePerSession.toString();
      _selectedYogaStyle = existing.yogaStyle;
      _selectedDifficultyLevel = existing.difficultyLevel;
      _isActive = existing.isActive;
      _latitudeController.text = existing.latitude?.toString() ?? '';
      _longitudeController.text = existing.longitude?.toString() ?? '';
      // TODO: Populate requirements and equipment from model when added
      
      final colorValue = int.tryParse(existing.color.substring(1), radix: 16);
      if (colorValue != null) {
        _groupColor = Color(0xFF000000 | colorValue);
      }
      
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
      
      const dayMap = {"Monday": "Mon", "Tuesday": "Tue", "Wednesday": "Wed", "Thursday": "Thu", "Friday": "Fri", "Saturday": "Sat", "Sunday": "Sun"};
      _selectedDays.addAll(existing.schedule.days.map((day) => dayMap[day]!).toList());

    } else {
      // --- CREATE MODE ---
      _maxParticipantsController.text = '20';
      _priceController.text = '0';
      _latitudeController.text = '22.7196'; // Default to Indore
      _longitudeController.text = '75.8577';
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = const TimeOfDay(hour: 8, minute: 0);
      
      // ADD THESE LINES to select the current day by default
      const dayMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
      final currentDay = dayMap[DateTime.now().weekday];
      if (currentDay != null) {
        _selectedDays = [currentDay];
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _groupNameController.dispose();
    _descriptionController.dispose();
    _locationTextController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _maxParticipantsController.dispose();
    _sessionDurationController.dispose();
    _priceController.dispose();
    _requirementsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  //----------------------------------------------------------------------------
  //  UI Helper Methods (Pickers, Dialogs)
  //----------------------------------------------------------------------------

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _showError('Location permissions are required to use this feature.');
          setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);

      // This re-uses the same logic as the map picker
      final apiService = Provider.of<ApiService>(context, listen: false);
      final locationData = await apiService.reverseGeocode(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _latitudeController.text = latLng.latitude.toStringAsFixed(5);
          _longitudeController.text = latLng.longitude.toStringAsFixed(5);
          _locationTextController.text = locationData['address'] ?? '';
        });
      }
    } catch (e) {
      _showError('Could not fetch current location. Please check your GPS settings.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(bool isStartDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)), // Allow past dates for editing
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = isStartTime
        ? _startTime ?? const TimeOfDay(hour: 7, minute: 0)
        : _endTime ?? const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Optional: Auto-adjust end time if it's before start time
          if (_endTime != null) {
              final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
              final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
              if (endMinutes < startMinutes) {
                  _endTime = picked.replacing(hour: picked.hour + 1);
              }
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _navigateToRepeatScreen() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => RepeatOptionsScreen(selectedDays: _selectedDays),
      ),
    );
    if (result != null) {
      setState(() => _selectedDays = result);
    }
  }

  Future<void> _showColorPicker() async {
    Color pickerColor = _groupColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Select'),
            onPressed: () {
              setState(() => _groupColor = pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openMapPicker() async {
    LatLng initialPoint = _selectedLocation ?? LatLng(
      double.tryParse(_latitudeController.text) ?? 22.7196,
      double.tryParse(_longitudeController.text) ?? 75.8577,
    );

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        LatLng tappedPoint = initialPoint;
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Select Location'),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.9,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialPoint,
                    initialZoom: 13.0,
                    onTap: (_, point) => setStateInDialog(() => tappedPoint = point),
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(markers: [
                      Marker(
                        point: tappedPoint,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ]),
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
        if (mounted) {
          setState(() {
            _locationTextController.text = locationData['address'] ?? '';
          });
        }
      } catch (e) {
        _showError('Could not fetch address for the selected point.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  //----------------------------------------------------------------------------
  //  Validation Methods
  //----------------------------------------------------------------------------

  String? _validateRequired(String? value, String fieldName) {
    return (value == null || value.trim().isEmpty) ? '$fieldName is required' : null;
  }
  
  String? _validateGroupName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Group name is required';
    if (v.length < 2) return 'Must be at least 2 characters';
    if (v.length > 100) return 'Cannot exceed 100 characters';
    return null;
  }

  String? _validateMaxParticipants(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'This field is required';
    final n = int.tryParse(v);
    if (n == null) return 'Please enter a valid number';
    if (n < 1) return 'Must be at least 1';
    if (n > 200) return 'Cannot exceed 200';
    return null;
  }

  String? _validatePrice(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Price is required';
    final p = double.tryParse(v);
    if (p == null) return 'Please enter a valid price';
    if (p < 0) return 'Price cannot be negative';
    return null;
  }

  //----------------------------------------------------------------------------
  //  Data Handling & Submission
  //----------------------------------------------------------------------------

  String _getRepeatSummary() {
    if (_selectedDays.isEmpty) return 'Does not repeat';
    const dayOrder = {"Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6, "Sun": 7};
    final sortedDays = List<String>.from(_selectedDays)..sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));
    if (sortedDays.length == 7) return 'Repeats daily';
    return 'Weekly on ${sortedDays.join(', ')}';
  }

  Future<void> _saveGroup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startTime == null || _endTime == null || _startDate == null || _endDate == null) {
      _showError('Please set a valid start and end time/date.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be before the start date.');
      return;
    }
    if (_selectedDays.isEmpty) {
      _showError('Please select at least one day for the schedule.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      const dayMap = {"Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday", "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday", "Sun": "Sunday"};
      final fullDayNames = _selectedDays.map((day) => dayMap[day]!).toList();

      final scheduleObject = {
        'startTime': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'endTime': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        'days': fullDayNames,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      };
      
      final colorString = '#${_groupColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      final groupData = {
        'group_name': _groupNameController.text.trim(),
        'location_text': _locationTextController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text.trim()),
        'longitude': double.tryParse(_longitudeController.text.trim()),
        'description': _descriptionController.text.trim(),
        'max_participants': int.parse(_maxParticipantsController.text.trim()),
        'yoga_style': _selectedYogaStyle,
        'difficulty_level': _selectedDifficultyLevel,
        'price_per_session': double.parse(_priceController.text.trim()),
        'color': colorString,
        'is_active': _isActive,
        'schedule': scheduleObject,
        // TODO: Add requirements and equipment to the payload
      };

      final apiService = Provider.of<ApiService>(context, listen: false);
      if (widget.existingGroup == null) {
        await apiService.createGroup(groupData);
      } else {
        await apiService.updateGroup(widget.existingGroup!.id, groupData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingGroup == null ? 'Group created!' : 'Group updated!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      _showError('Save failed: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //----------------------------------------------------------------------------
  //  BUILD METHOD
  //----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGroup != null;
    final theme = Theme.of(context);

    // Auto-calculate duration
    if (_startTime != null && _endTime != null) {
      final start = DateTime(2025, 1, 1, _startTime!.hour, _startTime!.minute);
      final end = DateTime(2025, 1, 1, _endTime!.hour, _endTime!.minute);
      final duration = end.difference(start);
      _sessionDurationController.text = !duration.isNegative ? duration.inMinutes.toString() : '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Group' : 'Create Group'),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8.0),
        //     child: FilledButton(
        //       onPressed: _isLoading ? null : _saveGroup,
        //       child: _isLoading
        //           ? const SizedBox(
        //               width: 20, height: 20,
        //               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        //           : const Text('Save'),
        //     ),
        //   ),
        // ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- CORE INFO (NEW UI) ---
            TextFormField(
              controller: _groupNameController,
              validator: _validateGroupName,
              style: theme.textTheme.headlineSmall,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Add title',
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Group Color'),
              trailing: CircleAvatar(backgroundColor: _groupColor, radius: 14),
              onTap: _showColorPicker,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: Text(DateFormat.yMMMEd().format(_startDate ?? DateTime.now())),
                    ),
                  ),
                  InkWell(
                    onTap: () => _pickTime(true),
                    child: Text((_startTime ?? TimeOfDay.now()).format(context)),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 40.0), // Align with leading icon
              title: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: Text(DateFormat.yMMMEd().format(_endDate ?? _startDate ?? DateTime.now())),
                    ),
                  ),
                  InkWell(
                    onTap: () => _pickTime(false),
                    child: Text((_endTime ?? TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1)).format(context)),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(_getRepeatSummary()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToRepeatScreen,
            ),
            const SizedBox(height: 16),
            
            // --- LOCATION (OLD CARD UI) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationTextController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        helperText: 'Full address or meeting point',
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (v) => _validateRequired(v, 'Address'),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _fetchCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Auto-Fetch'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _openMapPicker,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Pick on Map'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- SESSION DETAILS (OLD CARD UI) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedYogaStyle,
                      decoration: const InputDecoration(labelText: 'Yoga Style', prefixIcon: Icon(Icons.spa)),
                      items: _yogaStyles.map((style) => DropdownMenuItem(
                        value: style,
                        child: Text(style[0].toUpperCase() + style.substring(1)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedYogaStyle = v ?? 'hatha'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDifficultyLevel,
                      decoration: const InputDecoration(labelText: 'Difficulty Level', prefixIcon: Icon(Icons.trending_up)),
                      items: _difficultyLevels.map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.replaceAll('-', ' ').split(' ').map((l) => l[0].toUpperCase() + l.substring(1)).join(' ')),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedDifficultyLevel = v ?? 'all-levels'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sessionDurationController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes)',
                              prefixIcon: Icon(Icons.timer),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxParticipantsController,
                            decoration: const InputDecoration(labelText: 'Max Participants *', prefixIcon: Icon(Icons.people)),
                            validator: _validateMaxParticipants,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // --- PRICING (OLD CARD UI) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price per Session (₹) *',
                    helperText: 'Enter 0 for free classes',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: _validatePrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- ADDITIONAL INFO (OLD CARD UI) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        helperText: 'Describe your class, what makes it special, etc.',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _requirementsController,
                      decoration: const InputDecoration(
                        labelText: 'Requirements (Optional)',
                        helperText: 'e.g., Water bottle, Towel',
                        prefixIcon: Icon(Icons.checklist),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _equipmentController,
                      decoration: const InputDecoration(
                        labelText: 'Equipment Provided (Optional)',
                        helperText: 'e.g., Yoga mats, Blocks, Straps',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active Group'),
                      subtitle: const Text('Allow participants to see and join'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),

            // ADD THIS SIZEDBOX AT THE END
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveGroup,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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


          ],
        ),
      ),
    );
  }
}