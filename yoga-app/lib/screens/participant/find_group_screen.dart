// lib/screens/participant/find_group_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';

class FindGroupScreen extends StatefulWidget {
  final ApiService apiService;
  const FindGroupScreen({super.key, required this.apiService});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}

class _FindGroupScreenState extends State<FindGroupScreen> {
  final _searchController = TextEditingController();
  List<YogaGroup> _results = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _searched = true; });

    try {
      final list = await widget.apiService.getGroups(search: query);
      if (mounted) setState(() => _results = list);
    } catch (e) {
      if (mounted) _showError('Search failed: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(String groupId) async {
    setState(() => _loading = true);
    try {
      await widget.apiService.joinGroup(groupId: groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}');
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
              controller: _searchController,
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
                  // return Card(
                  //   child: ListTile(
                  //     title: Text(g.name),
                  //     subtitle: Text(g.locationText),
                  //     trailing: ElevatedButton(
                  //       onPressed: _loading ? null : () => _join(g.id),
                  //       child: const Text('Join'),
                  //     ),
                  //   ),
                  // );
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(g.locationText),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100, // ✅ constrain the button width
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _join(g.id),
                              child: const Text('Join'),
                            ),
                          ),
                        ],
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