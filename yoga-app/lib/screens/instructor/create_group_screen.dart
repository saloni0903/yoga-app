// lib/screens/instructor/create_group_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';

class CreateGroupScreen extends StatefulWidget {
  final ApiService api;
  final YogaGroup? existing;
  const CreateGroupScreen({super.key, required this.api, this.existing});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _timings = TextEditingController();
  String _style = 'hatha';
  String _difficulty = 'all-levels';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _location.text = e.locationText;
      _timings.text = e.timingText;
      _style = e.yogaStyle;
      _difficulty = e.difficulty;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        // create
        await widget.api.createGroup(
          groupname: _name.text.trim(),
          locationtext: _location.text.trim(),
          timingstext: _timings.text.trim(),
          yogastyle: _style,
          difficultylevel: _difficulty,
        );
      } else {
        // update
        await widget.api.updateGroup(
          id: widget.existing!.id,
          groupname: _name.text.trim(),
          locationtext: _location.text.trim(),
          timingstext: _timings.text.trim(),
          yogastyle: _style,
          difficultylevel: _difficulty,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() => _saving = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      helperText: 'e.g., Sunrise Vinyasa',
                    ),
                    validator: (v) => v == null || v.trim().length < 3
                        ? 'Enter a valid name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      helperText: 'City, studio, or park name',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter location' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _timings,
                    decoration: const InputDecoration(
                      labelText: 'Schedule',
                      helperText: 'e.g., Mon/Wed/Fri 6:30–7:30 AM',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter schedule' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _style,
                    items: const [
                      DropdownMenuItem(value: 'hatha', child: Text('Hatha')),
                      DropdownMenuItem(
                        value: 'vinyasa',
                        child: Text('Vinyasa'),
                      ),
                      DropdownMenuItem(
                        value: 'ashtanga',
                        child: Text('Ashtanga'),
                      ),
                      DropdownMenuItem(value: 'yin', child: Text('Yin')),
                      DropdownMenuItem(
                        value: 'restorative',
                        child: Text('Restorative'),
                      ),
                      DropdownMenuItem(value: 'power', child: Text('Power')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _style = v ?? 'hatha'),
                    decoration: const InputDecoration(labelText: 'Style'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    items: const [
                      DropdownMenuItem(
                        value: 'all-levels',
                        child: Text('All levels'),
                      ),
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text('Beginner'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text('Intermediate'),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text('Advanced'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _difficulty = v ?? 'all-levels'),
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save changes' : 'Create'),
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
