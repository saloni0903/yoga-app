// lib/screens/participant/find_group_screen.dart

import 'package:flutter/material.dart';
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

  // Helper method to show errors in a SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _searchGroups() async {
    final query = _searchController.text.trim();
    final apiService = Provider.of<ApiService>(context, listen: false);

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _groups = []; // Clear previous results
    });

    try {
      final results = await apiService.getGroups(search: query);
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted) {
        _showError(
          'Search failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup(String groupId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await apiService.joinGroup(groupId: groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop with a result to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Yoga Group'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by location or group name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoading ? null : _searchGroups,
                ),
              ),
              onSubmitted: (_) => _searchGroups(),
            ),
          ),

          // Loading Indicator
          if (_isLoading) const LinearProgressIndicator(),

          // Results List
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_searchPerformed) {
      return const Center(
        child: Text('Enter a search term to find groups.'),
      );
    }
    if (_groups.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No groups found matching your search.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _groups.length,
      itemBuilder: (_, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(group.locationText),
                // Text(group.instructorName),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _joinGroup(group.id),
                    child: const Text('Join Group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}