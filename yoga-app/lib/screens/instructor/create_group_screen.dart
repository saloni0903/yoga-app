// lib/screens/instructor/create_group_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';

class CreateGroupScreen extends StatefulWidget {
  final User user;
  const CreateGroupScreen({super.key, required this.user});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _timingsController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _apiService.createGroup(
        _nameController.text,
        _locationController.text,
        _timingsController.text,
        widget.user.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Group created successfully!")));
        Navigator.pop(context, true); // Pop and signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString())));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Yoga Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Group Name"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: "Location (e.g., Nehru Park, Indore)"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _timingsController, decoration: const InputDecoration(labelText: "Timings (e.g., Daily, 6 AM - 7 AM)"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create Group", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}