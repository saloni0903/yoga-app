import 'dart:io';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../api_service.dart';
import '../../models/user.dart';
import '../about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _samagraIdController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  // ⭐ ADDITION: State for the picked profile image file
  File? _profileImageFile;

  // ⭐ ADDITION: Flag to prevent controllers from being repopulated unnecessarily
  bool _controllersPopulated = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _samagraIdController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ⭐ CHANGE: This function is now only called when needed, not on every rebuild.
  void _populateControllers(User user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _samagraIdController.text = user.samagraId ?? '';
    _locationController.text = user.location;
    _controllersPopulated = true;
  }

  // ⭐ ADDITION: Image picking logic
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  // lib/screens/profile/profile_screen.dart

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // 1. Read bytes and get filename (if file exists)
      Uint8List? imageBytes;
      String? imageFileName;
      if (_profileImageFile != null) {
        imageBytes = await _profileImageFile!.readAsBytes();
        // Use package:path/path.dart to be safe, but this is a quick fix
        imageFileName = _profileImageFile!.path.split(r'\').last.split(r'/').last;
      }

      // 2. Call with new parameters
      await apiService.updateMyProfile(
        profileData: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'samagraId': _samagraIdController.text.trim(),
          'location': _locationController.text.trim(),
        },
        imageBytes: imageBytes, // <-- Pass the bytes
        imageFileName: imageFileName, // <-- Pass the name
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          _profileImageFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update failed: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ⭐ ADDITION: Added more robust validators for phone and Samagra ID
  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null; // Phone is optional
    if (phone.length != 10 || int.tryParse(phone) == null) {
      return 'Please enter a valid 10-digit phone number.';
    }
    return null;
  }

  String? _validateSamagraId(String? value) {
    final samagraId = value?.trim() ?? '';
    if (samagraId.isEmpty) return null; // Samagra ID is optional
    if (samagraId.length != 9 || int.tryParse(samagraId) == null) {
      return 'Please enter a valid 9-digit Samagra ID.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final user = apiService.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in.')));
        }

        // ⭐ CHANGE: Only populate controllers once to avoid losing user's edits.
        if (!_controllersPopulated) {
          _populateControllers(user);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _controllersPopulated =
                          false; // Reset to repopulate with original data
                      _profileImageFile =
                          null; // Discard picked image on cancel
                    });
                  },
                  child: const Text('Cancel'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profile',
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        // ⭐ CHANGE: Display the network image, the newly picked image, or the initial.
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : (user.profileImage != null
                                        ? NetworkImage(user.profileImage!)
                                        : null)
                                    as ImageProvider?,
                          child:
                              (_profileImageFile == null &&
                                  user.profileImage == null)
                              ? Text(
                                  '${user.firstName[0]}${user.lastName[0]}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                // ⭐ CHANGE: Hooked up the image picker function
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Center(
                    child: Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Divider(height: 40),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'First name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Last name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    // ⭐ CHANGE: Using the new, more specific validator.
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _samagraIdController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Samagra ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    // ⭐ CHANGE: Using the new, more specific validator.
                    validator: _validateSamagraId,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'City/Location',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 32),
                  if (_isEditing)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateProfile,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt_rounded),
                      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                    ),
                  if (!_isEditing) ...[
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About App'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                              FilledButton(
                                child: const Text('Logout'),
                                onPressed: () {
                                  apiService.logout();
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
