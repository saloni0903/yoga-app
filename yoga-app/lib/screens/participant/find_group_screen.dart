// lib/screens/participant/find_group_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';

class FindGroupScreen extends StatefulWidget {
  final ApiService apiService;
  const FindGroupScreen({super.key, required this.apiService});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}

class _FindGroupScreenState extends State<FindGroupScreen> {
  final _city = TextEditingController();
  List<YogaGroup> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    final query = _city.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final list = await widget.apiService.getGroups(search: query);
      setState(() => _results = list);
    } catch (e) {
      if (mounted) _showError('Search failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(String id) async {
    setState(() => _loading = true);
    try {
      await widget.apiService.joinGroup(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group successfully!')),
        );
      }
    } catch (e) {
      if (mounted) _showError('Join failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover groups')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Search by City'),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _search, child: const Text('Search')),
            if (_loading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final g = _results[i];
                  return Card(
                    child: ListTile(
                      title: Text(g.name),
                      subtitle: Text(g.locationText),
                      trailing: ElevatedButton(
                        onPressed: _loading ? null : () => _join(g.id),
                        child: const Text('Join'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}