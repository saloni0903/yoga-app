// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers to manage the form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false; // To toggle between view and edit mode

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  // Function to populate the form fields with user data
  void _populateControllers(User user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _locationController.text = user.location;
  }
  
  // Function to handle the profile update API call
  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.updateMyProfile({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Turn off editing mode after saving
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here so the UI updates if the profile changes
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final user = apiService.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in.')));
        }
        
        // Populate controllers with the latest user data
        _populateControllers(user);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              // Toggle between "Edit" and "Cancel" buttons
              if (_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
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
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            '${user.firstName[0]}${user.lastName[0]}',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: () { /* TODO: Implement image picking */ },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Center(
                    child: Text(user.email, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                  ),
                  const Divider(height: 40),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (v) => v!.isEmpty ? 'First name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                     validator: (v) => v!.isEmpty ? 'Last name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'City/Location'),
                    validator: (v) => v!.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 32),
                  // Only show the Save button when in editing mode
                  if (_isEditing)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateProfile,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_alt_rounded),
                      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}