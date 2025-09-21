// lib/screens/participant/my_groups_screen.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import '../participant/group_detail_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  final ApiService api;
  const MyGroupsScreen({super.key, required this.api});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  late Future<List<YogaGroup>> _future;

  @override
  void initState() {
    super.initState();
    // For MVP we list active groups and let user filter; optional: add a dedicated endpoint for "my groups".
    _future = widget.api.getGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: FutureBuilder<List<YogaGroup>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed: ${snap.error}'));
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('No groups joined yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final g = groups[i];
              return Card(
                child: ListTile(
                  title: Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${g.locationText} • ${g.yogaStyle} • ${g.difficulty}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(groupId: g.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
