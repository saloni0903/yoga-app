// lib/screens/participant/find_group_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';

class FindGroupScreen extends StatefulWidget {
  const FindGroupScreen({super.key});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}

class _FindGroupScreenState extends State<FindGroupScreen> {
  final _searchController = TextEditingController();
  List<YogaGroup> _groups = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  bool _isMapView = false; // To toggle between list and map

  Future<void> _searchGroups() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      // Use the existing text-based search from your ApiService
      final results = await apiService.getGroups(search: query);
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted)
        _showError(
          'Search failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(String groupId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _loading = true);
    try {
      await apiService.joinGroup(groupId: groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted)
        _showError(
          'Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Yoga Group'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by location or group name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchGroups,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _searchGroups(),
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
