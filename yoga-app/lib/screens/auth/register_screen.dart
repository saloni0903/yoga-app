import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();

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

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final user = await _apiService.register(
        fullName: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        // ✅ Pass apiService forward
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(user: user, apiService: _apiService),
          ),
        );
      }
    } catch (e) {
      // FIX: Add debug print to see errors in the console
      debugPrint('Registration failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              e.toString().replaceFirst("Exception: ", ""),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
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
            padding:
                const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header / Branding
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.self_improvement,
                        color: cs.onPrimaryContainer,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join YES Yoga',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),

                  // Role selection
                  Text(
                    'I am a...',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
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
                                    decoration: const InputDecoration(
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
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: _validateEmail,
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _register(),
                              decoration: const InputDecoration(
                                labelText: 'Your City',
                                helperText: 'e.g., Indore',
                                prefixIcon:
                                    Icon(Icons.location_city_outlined),
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
