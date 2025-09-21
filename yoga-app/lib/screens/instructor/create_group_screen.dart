import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';

class CreateGroupScreen extends StatefulWidget {
  final ApiService api;
  final User currentUser;
  final YogaGroup? existing;

  const CreateGroupScreen({
    super.key,
    required this.api,
    required this.currentUser,
    this.existing,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

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
    _initializeForm();
  }

  void _initializeForm() {
    final existing = widget.existing;
    if (existing != null) {
      // Edit mode - populate existing values
      _groupNameController.text = existing.name;
      _locationController.text = existing.location ?? '';
      _locationTextController.text = existing.locationText;
      _timingsController.text = existing.timingText;
      _descriptionController.text = existing.description ?? '';
      _maxParticipantsController.text = existing.maxParticipants.toString();
      _sessionDurationController.text = existing.sessionDuration.toString();
      _priceController.text = existing.pricePerSession.toString();
      _currencyController.text = existing.currency ?? 'INR';
      _selectedYogaStyle = existing.yogaStyle;
      _selectedDifficultyLevel = existing.difficultyLevel;
      _isActive = existing.isActive;
      _requirementsController.text = (existing.requirements ?? []).join(', ');
      _equipmentController.text = (existing.equipmentNeeded ?? []).join(', ');
      _latitudeController.text = existing.latitude?.toString() ?? '';
      _longitudeController.text = existing.longitude?.toString() ?? '';
    } else {
      // Create mode - set defaults
      _maxParticipantsController.text = '20';
      _sessionDurationController.text = '60';
      _priceController.text = '0';
      _currencyController.text = 'RUPEE';
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

  String? _validateTimings(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Timings are required';
    if (v.length > 200) return 'Timings cannot exceed 200 characters';
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

  Future<void> _saveGroup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final requirements = _requirementsController.text.trim().isNotEmpty
          ? _requirementsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];

      final equipment = _equipmentController.text.trim().isNotEmpty
          ? _equipmentController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];

      if (widget.existing == null) {
        // Create new group
        await widget.api.createGroup(
          groupName: _groupNameController.text.trim(),
          location: _locationController.text.trim(),
          locationText: _locationTextController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          timingsText: _timingsController.text.trim(),
          description: _descriptionController.text.trim(),
          maxParticipants: int.parse(_maxParticipantsController.text.trim()),
          yogaStyle: _selectedYogaStyle,
          difficultyLevel: _selectedDifficultyLevel,
          sessionDuration: int.parse(_sessionDurationController.text.trim()),
          pricePerSession: double.parse(_priceController.text.trim()),
          currency: _currencyController.text.trim(),
          requirements: requirements,
          equipmentNeeded: equipment,
          isActive: _isActive,
          instructorId: widget.currentUser.id,
        );
      } else {
        // Update existing group
        await widget.api.updateGroup(
          id: widget.existing!.id,
          groupName: _groupNameController.text.trim(),
          location: _locationController.text.trim(),
          locationText: _locationTextController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          timingsText: _timingsController.text.trim(),
          description: _descriptionController.text.trim(),
          maxParticipants: int.parse(_maxParticipantsController.text.trim()),
          yogaStyle: _selectedYogaStyle,
          difficultyLevel: _selectedDifficultyLevel,
          sessionDuration: int.parse(_sessionDurationController.text.trim()),
          pricePerSession: double.parse(_priceController.text.trim()),
          currency: _currencyController.text.trim(),
          requirements: requirements,
          equipmentNeeded: equipment,
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Group created successfully!'
                : 'Group updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
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
    _sessionDurationController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _requirementsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude *',
                                helperText: '-90 to 90',
                                prefixIcon: Icon(Icons.my_location),
                              ),
                              validator: _validateLatitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*\.?\d*'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude *',
                                helperText: '-180 to 180',
                                prefixIcon: Icon(Icons.location_searching),
                              ),
                              validator: _validateLongitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*\.?\d*'),
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

                      // Timings
                      TextFormField(
                        controller: _timingsController,
                        decoration: const InputDecoration(
                          labelText: 'Class Timings *',
                          helperText: 'e.g., "Mon-Fri 6:00 AM - 7:00 AM"',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        validator: _validateTimings,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Session Duration and Max Participants Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sessionDurationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes) *',
                                helperText: '15-180 min',
                                prefixIcon: Icon(Icons.timer),
                              ),
                              validator: _validateSessionDuration,
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
                              decoration: const InputDecoration(
                                labelText: 'Max Participants *',
                                helperText: '1-100',
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                              decoration: const InputDecoration(
                                labelText: 'Price per Session *',
                                helperText: 'Enter 0 for free',
                                prefixIcon: Icon(Icons.monetization_on),
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
