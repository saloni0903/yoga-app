// lib/screens/instructor/instructor_dashboard.dart
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';
import '../../models/yoga_group.dart';
import '../qr/qr_display_screen.dart';
import '../participant/group_detail_screen.dart';
import 'create_group_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final User user;
  const InstructorDashboard({super.key, required this.user});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _index = 0;
  late final ApiService _api;
  late Future<List<YogaGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _groupsFuture = _api.getGroups(page: 1, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _UpcomingTab(api: _api, groupsFuture: _groupsFuture),
      _HistoryTab(api: _api, groupsFuture: _groupsFuture),
      _ManageTab(api: _api),
    ];
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            label: 'Upcoming',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_outlined),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Manage',
          ),
        ],
      ),
      body: pages[_index],
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  final ApiService api;
  final Future<List<YogaGroup>> groupsFuture;
  const _UpcomingTab({required this.api, required this.groupsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<YogaGroup>>(
      future: groupsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        final groups = snap.data ?? [];
        if (groups.isEmpty) return const Center(child: Text('No groups yet'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final g = groups[i];
            return Card(
              child: ListTile(
                title: Text(
                  g.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${g.locationText}\n${g.timingText}'),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Generate QR',
                      icon: const Icon(Icons.qr_code_2),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QrDisplayScreen(api: api, group: g),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateGroupScreen(api: api, existing: g),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(api: api, groupId: g.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final ApiService api;
  final Future<List<YogaGroup>> groupsFuture;
  const _HistoryTab({required this.api, required this.groupsFuture});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  YogaGroup? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder<List<YogaGroup>>(
            future: widget.groupsFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              final groups = snap.data ?? [];
              return DropdownButtonFormField<YogaGroup>(
                value: _selected,
                decoration: const InputDecoration(labelText: 'Select group'),
                items: groups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                    .toList(),
                onChanged: (g) => setState(() => _selected = g),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Choose a group to view history'))
              : _GroupHistoryList(api: widget.api, group: _selected!),
        ),
      ],
    );
  }
}

class _GroupHistoryList extends StatefulWidget {
  final ApiService api;
  final YogaGroup group;
  const _GroupHistoryList({required this.api, required this.group});

  @override
  State<_GroupHistoryList> createState() => _GroupHistoryListState();
}

class _GroupHistoryListState extends State<_GroupHistoryList> {
  @override
  Widget build(BuildContext context) {
    // For MVP, reuse participant detail which lists attendance items (instructor can view per-group aggregates later)
    return Center(
      child: Text('Past sessions for "${widget.group.name}" will appear here'),
    );
  }
}

class _ManageTab extends StatelessWidget {
  final ApiService api;
  const _ManageTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add group/session'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateGroupScreen(api: api)),
          );
        },
      ),
    );
  }
}
