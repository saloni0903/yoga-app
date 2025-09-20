// lib/screens/instructor/create_group_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';

class CreateGroupScreen extends StatefulWidget {
  final ApiService api;
  final User currentUser;
  final YogaGroup? existing;
  const CreateGroupScreen({super.key, required this.api, required this.currentUser, this.existing});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _timings = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _location.text = e.locationText;
      _timings.text = e.timingText;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.api.createGroup(
          groupName: _name.text.trim(),
          location: _location.text.trim(),
          timings: _timings.text.trim(),
        );
      } else {
        await widget.api.updateGroup(
          id: widget.existing!.id,
          groupName: _name.text.trim(),
          location: _location.text.trim(),
          timings: _timings.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _timings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Group' : 'Create Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Group Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _timings, decoration: const InputDecoration(labelText: 'Timings'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : Text(isEdit ? 'Save Changes' : 'Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}