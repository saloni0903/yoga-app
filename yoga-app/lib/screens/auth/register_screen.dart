import '../../api_service.dart';
import '../home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// lib/screens/auth/register_screen.dart

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'participant';
  bool _isLoading = false;
  bool _obscurePw = true;

  // Strong password regex: >=8, 1 upper, 1 lower, 1 digit, 1 special
  final _passwordRegex = RegExp(
    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$',
  );

  String? _validateName(String? value, String label) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';
    if (v.length <= 2) return '$label must be longer than 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!v.contains('@')) return 'Email must contain @';
    if (!v.endsWith('.com')) return 'Email must end with .com';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (!_passwordRegex.hasMatch(v)) {
      return 'Min 8 chars, include upper, lower, digit, special';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Location is required';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    if (v.length != 10) return 'Phone number must be 10 digits';
    if (int.tryParse(v) == null) return 'Invalid phone number';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final apiService = Provider.of<ApiService>(context, listen: false);

    setState(() => _isLoading = true);
    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // The register method will automatically log the user in and notify all listeners.
      await apiService.register(
        fullName: fullName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        // If the registration screen is on top of the login screen, pop it.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString().replaceFirst("Exception: ", "")),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Helper function to show errors
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Logic to get current location and fill the city field
  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final locationData = await apiService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // FIX: Slightly reduce horizontal padding to fix overflow
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/logo.png', // Path to your logo
                      width: 100,        // You can adjust the size
                      height: 100,       // You can adjust the size
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join YES Yoga',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role selection
                  Text(
                    'I am a...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'participant',
                        icon: Icon(Icons.favorite_outline),
                        label: Text('Participant'),
                      ),
                      ButtonSegment(
                        value: 'instructor',
                        icon: Icon(Icons.school_outlined),
                        label: Text('Instructor'),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedRole = set.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 20),

                  // Form card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'First name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (v) =>
                                        _validateName(v, 'First name'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Last name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (v) =>
                                        _validateName(v, 'Last name'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined),
                                helperText:
                                    'Must be of 10 digits',

                              ),
                              validator: _validatePhone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePw,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                helperText:
                                    'Min 8, upper + lower + digit + special',
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscurePw = !_obscurePw),
                                  icon: Icon(
                                    _obscurePw
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16), // This is the end of the Password field

                            // ▼▼▼ ADD THIS CONFIRM PASSWORD FIELD ▼▼▼
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePw,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: _validateConfirmPassword,
                            ),
                            // This is the CORRECT code block
                            TextFormField(
                              controller: _locationController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _register(),
                              decoration: InputDecoration( // <-- Notice 'const' is gone
                                labelText: 'Your City',
                                helperText: 'e.g., Indore',
                                prefixIcon: const Icon(Icons.location_city_outlined),
                                // ▼▼▼ ADD THIS SUFFIX ICON ▼▼▼
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.my_location),
                                  tooltip: 'Auto-Fetch My City',
                                  onPressed: _isLoading ? null : _fetchLocation,
                                ),
                                // ▲▲▲ END OF SUFFIX ICON ▲▲▲
                              ),
                              validator: _validateLocation,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _register,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
