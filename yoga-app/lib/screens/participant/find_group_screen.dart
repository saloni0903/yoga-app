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
  String? _error;

  Future<void> _search() async {
    final query = _city.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.apiService.getGroups(
        search: query,
        page: 1,
        limit: 30,
      );
      setState(() => _results = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Search failed: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(String id) async {
    setState(() => _loading = true);
    try {
      await widget.apiService.joinGroup(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Joined group')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Join failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _city.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover groups')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
                helperText: 'Search by city or location',
              ),
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: hasQuery && !_loading
                          ? const Text('No groups found for this search')
                          : const Text('Enter a city and tap Search'),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final g = _results[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              g.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${g.locationText} • ${g.yogaStyle} • ${g.difficulty}',
                            ),
                            trailing: FilledButton(
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
